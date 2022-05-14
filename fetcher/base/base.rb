# frozen_string_literal: true
require "set"
require "objspace"

class Fetcher
  attr_reader :namespaces, :classes, :methods, :attributes
  @library = nil
  @name = nil
  @url = nil
  NamespaceData = Struct.new(:id, :name)
  ClassData = Struct.new(:id, :parent, :name, :full_name, :url, :document)
  MethodData = Struct.new(:id, :parent, :name, :full_name, :url, :parameters, :document)
  AttributeData = Struct.new(:id, :parent, :name, :full_name, :url, :document)
  SEPARATOR = "/"

  def initialize
    @namespaces = []
    @classes = []
    @methods = []
    @attributes = []
  end

  def fetch
    raise NotImplementedError
  end

  def save(db)
    db[:libraries].insert(
      id: self.class.library,
      name: self.class.name,
      url: self.class.url,
    )
    fetch
    [
      @attributes,
      @classes,
      @methods,
      @namespaces,
    ].each { _1.uniq!(&:id) }
    Console.info "#{self.class.name}を保存中..."
    Console.info "  #{@namespaces.size}個の名前空間を保存中..."
    db[:namespaces].multi_insert(
      @namespaces.map { |item|
        {
          library: self.class.library,
          **item.to_h,
        }
      }
    )

    Console.info "  #{@classes.size}個のクラスを保存中..."
    db[:classes].multi_insert(
      @classes.map { |item|
        {
          library: self.class.library,
          **item.to_h,
        }
      }
    )

    Console.info "  #{@methods.size}個のメソッドを保存中..."
    db[:methods].multi_insert(
      @methods.map { |item|
        {
          library: self.class.library,
          **item.to_h,
        }
      }
    )

    Console.info "  #{@attributes.size}個の属性を保存中..."
    db[:attributes].multi_insert(
      @attributes.map { |item|
        {
          library: self.class.library,
          **item.to_h,
        }
      }
    )
  end

  class << self
    attr_reader :library, :name, :url, :color

    def save_all(db)
      fetchers.map do |klass|
        Thread.new(klass) do |kls|
          Thread.current[:kls] = kls
          Console.info "#{kls.name}を保存中..."
          kls.new.save(db)
          Console.success "#{kls.name}を保存しました"
        end
      end.each(&:join)
    end

    def fetchers
      ObjectSpace.each_object(Class)
        .filter { |klass| klass < self }
        .filter(&:name)
    end
  end
end
