Curly
=======

Free your views!

Curly is a template language that completely separates structure and logic.
Instead of interspersing your HTML with snippets of Ruby, all logic is moved
to a presenter class, with only simple placeholders in the HTML.

While the basic concepts are very similar to [Mustache](http://mustache.github.com/)
or [Handlebars](http://handlebarsjs.com/), Curly is different in some key ways:

- Instead of the template controlling the variable scope and looping through
  data, all logic is left to the presenter object. This means that untrusted
  templates can safely be executed, making Curly a possible alternative to
  languages like [Liquid](http://liquidmarkup.org/).
- Instead of implementing its own template resolution mechanism, Curly hooks
  directly into Rails, leveraging the existing resolvers.
- Because of its close integration with Rails, with Curly you can easily set
  up caching for your views and partials.


### Table of Contents

1. [Installing](#installing)
2. [How to use Curly](#how-to-use-curly)
    1. [Identifiers](#identifiers)
    1. [Attributes](#attributes)
    1. [Conditional blocks](#conditional-blocks)
    1. [Collection blocks](#collection-blocks)
    1. [Setting up state](#setting-up-state)
    2. [Escaping Curly syntax](#escaping-curly-syntax)
    2. [Comments](#comments)
3. [Presenters](#presenters)
    1. [Layouts and Content Blocks](#layouts-and-content-blocks)
    2. [Examples](#examples)
4. [Caching](#caching)


Installing
----------

Installing Curly is as simple as running `gem install curly-templates`. If you're
using Bundler to manage your dependencies, add this to your Gemfile

```ruby
gem 'curly-templates'
```


How to use Curly
----------------

In order to use Curly for a view or partial, use the suffix `.curly` instead of
`.erb`, e.g. `app/views/posts/_comment.html.curly`. Curly will look for a
corresponding presenter class named `Posts::CommentPresenter`. By convention,
these are placed in `app/presenters/`, so in this case the presenter would
reside in `app/presenters/posts/comment_presenter.rb`. Note that presenters
for partials are not prepended with an underscore.

Add some HTML to the partial template along with some Curly components:

```html
<!-- app/views/posts/_comment.html.curly -->
<div class="comment">
  <p>
    {{author_link}} posted {{time_ago}} ago.
  </p>

  {{body}}

  {{#author?}}
    <p>{{deletion_link}}</p>
  {{/author?}}
</div>
```

The presenter will be responsible for providing the data for the components. Add
the necessary Ruby code to the presenter:

```ruby
# app/presenters/posts/comment_presenter.rb
class Posts::CommentPresenter < Curly::Presenter
  presents :comment

  def body
    BlueCloth.new(@comment.body).to_html
  end

  def author_link
    link_to @comment.author.name, @comment.author, rel: "author"
  end
  
  def deletion_link
    link_to "Delete", @comment, method: :delete
  end

  def time_ago
    time_ago_in_words(@comment.created_at)
  end
  
  def author?
    @comment.author == current_user
  end
end
```

The partial can now be rendered like any other, e.g. by calling

```ruby
render 'comment', comment: comment
render comment
render collection: post.comments
```

### Identifiers

Curly components can specify an _identifier_ using the so-called dot notation: `{{x.y.z}}`.
This can be very useful if the data you're accessing is hierarchical in nature. One common
example is I18n:

```html
<h1>{{i18n.homepage.header}}</h1>
```

```ruby
# In the presenter, the identifier is passed as an argument to the method. The
# argument will always be a String.
def i18n(key)
  translate(key)
end
```

The identifier is separated from the component name with a dot. If the presenter method
has a default value for the argument, the identifier is optional – otherwise it's mandatory.


### Attributes

In addition to [an identifier](#identifiers), Curly components can be annotated
with *attributes*. These are key-value pairs that affect how a component is rendered.

The syntax is reminiscent of HTML:

```html
<div>{{sidebar rows=3 width=200px title="I'm the sidebar!"}}</div>
```

The presenter method that implements the component must have a matching keyword argument:

```ruby
def sidebar(rows: "1", width: "100px", title:); end
```

All argument values will be strings. A compilation error will be raised if

- an attribute is used in a component without a matching keyword argument being present
  in the method definition; or
- a required keyword argument in the method definition is not set as an attribute in the
  component.

You can define default values using Ruby's own syntax.


### Conditional blocks

If there is some content you only want rendered under specific circumstances, you can
use _conditional blocks_. The `{{#admin?}}...{{/admin?}}` syntax will only render the
content of the block if the `admin?` method on the presenter returns true, while the
`{{^admin?}}...{{/admin?}}` syntax will only render the content if it returns false.

Both forms can have an identifier: `{{#locale.en?}}...{{/locale.en?}}` will only
render the block if the `locale?` method on the presenter returns true given the
argument `"en"`. Here's how to implement that method in the presenter:

```ruby
class SomePresenter < Curly::Presenter
  # Allows rendering content only if the locale matches a specified identifier.
  def locale?(identifier)
    current_locale == identifier
  end
end
```

Furthermore, attributes can be set on the block. These only need to be specified when
opening the block, not when closing it:

```html
{{#square? width=3 height=3}}
  <p>It's square!</p>
{{/square?}}
```

Attributes work the same way as they do for normal components.


### Collection blocks

Sometimes you want to render one or more items within the current template, and splitting
out a separate template and rendering that in the presenter is too much overhead. You can
instead define the template that should be used to render the items inline in the current
template using the _collection block syntax_.

Collection blocks are opened using an asterisk:

```html
{{*comments}}
  <li>{{body}} ({{author_name}})</li>
{{/comments}}
```

The presenter will need to expose the method `#comments`, which should return a collection
of objects:

```ruby
class Posts::ShowPresenter < Curly::Presenter
  presents :post

  def comments
    @post.comments
  end
end
```

The template within the collection block will be used to render each item, and it will
be backed by a presenter named after the component – in this case, `comments`. The name
will be singularized and Curly will try to find the presenter class in the following
order:

* `Posts::ShowPresenter::CommentPresenter`
* `Posts::CommentPresenter`
* `CommentPresenter`

This allows you some flexibility with regards to how you want to organize these nested
templates and presenters.

Note that the nested template will *only* have access to the methods on the nested
presenter, but all variables passed to the "parent" presenter will be forwarded to
the nested presenter. In addition, the current item in the collection will be
passed, as well as that item's index in the collection:

```ruby
class Posts::CommentPresenter < Curly::Presenter
  presents :post, :comment, :comment_counter

  def number
    # `comment_counter` is automatically set to the item's index in the collection,
    # starting with 1.
    @comment_counter
  end

  def body
    @comment.body
  end

  def author_name
    @comment.author.name
  end
end
```

Collection blocks are an alternative to splitting out a separate template and rendering
that from the presenter – which solution is best depends on your use case.


### Setting up state

Although most code in Curly presenters should be free of side effects, sometimes side
effects are required. One common example is defining content for a `content_for` block.

If a Curly presenter class defines a `setup!` method, it will be called before the view
is rendered:

```ruby
class PostPresenter < Curly::Presenter
  presents :post

  def setup!
    content_for :title, post.title

    content_for :sidebar do
      render 'post_sidebar', post: post
    end
  end
end
```

### Escaping Curly syntax

In order to have `{{` appear verbatim in the rendered HTML, use the triple Curly escape syntax:

```
This is {{{escaped}}.
```

You don't need to escape the closing `}}`.


### Comments

If you want to add comments to your Curly templates that are not visible in the rendered HTML,
use the following syntax:

```html
{{! This is some interesting stuff }}
```


Presenters
----------

Presenters are classes that inherit from `Curly::Presenter` – they're usually placed in
`app/presenters/`, but you can put them anywhere you'd like. The name of the presenter
classes match the virtual path of the view they're part of, so if your controller is
rendering `posts/show`, the `Posts::ShowPresenter` class will be used. Note that Curly
is only used to render a view if a template can be found – in this case, at
`app/views/posts/show.html.curly`.

Presenters can declare a list of accepted variables using the `presents` method:

```ruby
class Posts::ShowPresenter < Curly::Presenter
  presents :post
end
```

A variable can have a default value:

```ruby
class Posts::ShowPresenter < Curly::Presenter
  presents :post
  presents :comment, default: nil
end
```

Any public method defined on the presenter is made available to the template as
a component:

```ruby
class Posts::ShowPresenter < Curly::Presenter
  presents :post
  
  def title
    @post.title
  end
  
  def author_link
    # You can call any Rails helper from within a presenter instance:
    link_to author.name, profile_path(author), rel: "author"
  end
  
  private
  
  # Private methods are not available to the template, so they're safe to
  # use.
  def author
    @post.author
  end
end
```

Presenter methods can even take an argument. Say your Curly template has the content
`{{t.welcome_message}}`, where `welcome_message` is an I18n key. The following presenter
method would make the lookup work:

```ruby
def t(key)
  translate(key)
end
```

That way, simple ``functions'' can be added to the Curly language. Make sure these do not
have any side effects, though, as an important part of Curly is the idempotence of the
templates.


### Layouts and Content Blocks

Both layouts and content blocks (see [`content_for`](http://api.rubyonrails.org/classes/ActionView/Helpers/CaptureHelper.html#method-i-content_for))
use `yield` to signal that content can be inserted. Curly works just like ERB, so calling
`yield` with no arguments will make the view usable as a layout, while passing a Symbol
will make it try to read a content block with the given name:

```ruby
# Given you have the following Curly template in
# app/views/layouts/application.html.curly
#
#   <html>
#     <head>
#       <title>{{title}}</title>
#     </head>
#     <body>
#       <div id="sidebar">{{sidebar}}</div>
#       {{body}}
#     </body>
#   </html>
#
class ApplicationLayout < Curly::Presenter
  def title
    "You can use methods just like in any other presenter!"
  end
  
  def sidebar
    # A view can call `content_for(:sidebar) { "some HTML here" }`
    yield :sidebar
  end
  
  def body
    # The view will be rendered and inserted here:
    yield
  end
end
```


### Examples

Here is a simple Curly template – it will be looked up by Rails automatically.

```html
<!-- app/views/posts/show.html.curly -->
<h1>{{title}}<h1>
<p class="author">{{author}}</p>
<p>{{description}}</p>

{{comment_form}}

<div class="comments">
  {{comments}}
</div>
```

When rendering the template, a presenter is automatically instantiated with the
variables assigned in the controller or the `render` call. The presenter declares
the variables it expects with `presents`, which takes a list of variables names.

```ruby
# app/presenters/posts/show_presenter.rb
class Posts::ShowPresenter < Curly::Presenter
  presents :post

  def title
    @post.title
  end

  def author
    link_to(@post.author.name, @post.author, rel: "author")
  end

  def description
    Markdown.new(@post.description).to_html.html_safe
  end

  def comments
    render 'comment', collection: @post.comments
  end

  def comment_form
    if @post.comments_allowed?
      render 'comment_form', post: @post
    else
      content_tag(:p, "Comments are disabled for this post")
    end
  end
end
```


Caching
-------

Caching is handled at two levels in Curly – statically and dynamically. Static caching
concerns changes to your code and templates introduced by deploys. If you do not wish
to clear your entire cache every time you deploy, you need a way to indicate that some
view, helper, or other piece of logic has changed.

Dynamic caching concerns changes that happen on the fly, usually made by your users in
the running system. You wish to cache a view or a partial and have it expire whenever
some data is updated – usually whenever a specific record is changed.


### Dynamic Caching

Because of the way logic is contained in presenters, caching entire views or partials
by the data they present becomes exceedingly straightforward. Simply define a
`#cache_key` method that returns a non-nil object, and the return value will be used to
cache the template.

Whereas in ERB you would include the `cache` call in the template itself:

```erb
<% cache([@post, signed_in?]) do %>
  ...
<% end %>
```

In Curly you would instead declare it in the presenter:

```ruby
class Posts::ShowPresenter < Curly::Presenter
  presents :post

  def cache_key
    [@post, signed_in?]
  end
end
```

Likewise, you can add a `#cache_duration` method if you wish to automatically expire
the fragment cache:

```ruby
class Posts::ShowPresenter < Curly::Presenter
  ...

  def cache_duration
    30.minutes
  end
end
```


### Static Caching

Static caching will only be enabled for presenters that define a non-nil `#cache_key`
method (see [Dynamic Caching.](#dynamic-caching))

In order to make a deploy expire the cache for a specific view, set the version of the
view to something new, usually by incrementing by one:

```ruby
class Posts::ShowPresenter < Curly::Presenter
  version 3

  def cache_key
    # Some objects
  end
end
```

This will change the cache keys for all instances of that view, effectively expiring
the old cache entries.

This works well for views, or for partials that are rendered in views that themselves
are not cached. If the partial is nested within a view that _is_ cached, however, the
outer cache will not be expired. The solution is to register that the inner partial
is a dependency of the outer one such that Curly can automatically deduce that the
outer partial cache should be expired:

```ruby
class Posts::ShowPresenter < Curly::Presenter
  version 3
  depends_on 'posts/comment'

  def cache_key
    # Some objects
  end
end

class Posts::CommentPresenter < Curly::Presenter
  version 4
  depends_on 'posts/comment'

  def cache_key
    # Some objects
  end
end
```

Now, if the version of `Posts::CommentPresenter` is bumped, the cache keys for both
presenters would change. You can register any number of view paths with `depends_on`.

If you use [Cache Digests](https://github.com/rails/cache_digests), Curly will
automatically provide a list of dependencies. This will allow you to deploy changes
to your templates and have the relevant caches automatically expire.


Thanks
------

Thanks to [Zendesk](http://zendesk.com/) for sponsoring the work on Curly.


### Contributors

- Daniel Schierbeck ([@dasch](https://github.com/dasch))
- Benjamin Quorning ([@bquorning](https://github.com/bquorning))
- Jeremy Rodi ([@redjazz96](https://github.com/redjazz96))
- Alisson Cavalcante Agiani ([@thelinuxlich](https://github.com/thelinuxlich))


Build Status
------------

[![Build Status](https://travis-ci.org/zendesk/curly.png?branch=master)](https://travis-ci.org/zendesk/curly)


Copyright and License
---------------------

Copyright (c) 2013 Daniel Schierbeck (@dasch), Zendesk Inc.

Licensed under the [Apache License Version 2.0](http://www.apache.org/licenses/LICENSE-2.0).
