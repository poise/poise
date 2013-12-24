# Poise

[![Build Status](https://travis-ci.org/poise/poise.png?branch=master)](https://travis-ci.org/poise/poise)

The poise cookbook provides patterns and helpers for writing reusable Chef
code.

## Quick start

Create a `libraries/default.rb` file in your cookbook like so:

```ruby
class Chef
  class Resource::MyResource < Resource
    include Poise
    actions(:enable, :disable)
    attribute(:path, kind_of: String)
  end

  class Provider::MyResource < Provider
    def action_enable
      converge_by("enable resource #{new_resource.name}") do
        notifying_block do
          ... # Normal Chef recipe code goes here
        end
      end
    end
  end
end
```

You can then use this resource like any other Chef resource:

```ruby
my_resource 'one' do
  path '/tmp'
end
```

## Patterns

### Notifying Block

Module: `Poise::Provider::NotifyingBlock`



### Include Recipe

### Sub-resources

#### Container

#### Child

### Lazy Attribute Default

### Option Collector

## Helpers

### LWRP API

### Resource Name

## Using the Poise module

