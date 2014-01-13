Changelog
=========

v1.0.4
------

* Redeclaring a template attribute with the same name as a parent class will
  inherit its options.

v1.0.2
------

* New template attribute pattern.

```ruby
attribute(:config, template: true)

...

resource 'name' do
  config_source 'template.erb'
end

...

new_resource.config_content
```

v1.0.0
------

* Initial release!
