# Changelog

## v2.0.0

Major overhaul! Poise is now a Halite gem/cookbook. New helpers:

* ChefspecMatchers – Automatically create Chefspec matchers for Poise resources.
* DefinedIn – Track which file (and cookbook) a resource or provider is defined in.
* Fused – Experimental support for defining provider actions in the resource class.
* Inversion – Support for end-user dependency inversion with providers.

All helpers are compatible with Chef >= 12.0. Chef 11 is now deprecated, if you
need to support Chef 11 please continue to use Poise 1.

## v1.0.12

* Correctly propagate errors from inside notifying_block.

## v1.0.10

* Fixes an issue with the LWRPPolyfill helper and false values.


## v1.0.8

* Delayed notifications from nested converges will still only run at the end of
  the main converge.

## v1.0.6

* The include_recipe helper now works correctly when used at compile time.

## v1.0.4

* Redeclaring a template attribute with the same name as a parent class will
  inherit its options.

## v1.0.2

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

## v1.0.0

* Initial release!
