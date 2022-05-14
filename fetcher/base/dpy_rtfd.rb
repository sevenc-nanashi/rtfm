# frozen_string_literal: true
require "http"
require "nokogiri"
require "rsplit"

require_relative "base"

class Fetcher::DpyRtfd < Fetcher
  @color = "\e[44m"

  def fetch
    self.class.urls.each do |url|
      Console.info "#{url}を取得中..."
      html = HTTP.get(url).to_s
      # @type [Nokogiri::HTML::Document]
      parsed = Nokogiri::HTML.parse(html)
      namespace_nodes = parsed.css(".sig-prename.descclassname")
      namespace_nodes.map do |node|
        node.text.strip.sub(/\.\Z/, "")
      end.uniq.each do |name|
        next if name == "@"
        @namespaces << NamespaceData.new(
          [self.class.library, name].join(SEPARATOR),
          name,
        )
      end
      Console.info "  トップレベル関数を取得中..."
      function_nodes = parsed.css("dl.py.function")
      function_nodes.each do |node|
        full_name = node.at_css("dt")["id"]
        namespace_name, name = full_name.rsplit(".", 2)
        namespace_name.gsub!(/^([^.]+)\.\1/, "\\1")
        namespace = @namespaces.find { |item| item.name == namespace_name }
        function_url = url + node.at_css("a.headerlink")["href"]
        document_node = node.at_css("dd")
        document = parsed.css(document_node.css_path + "> p").map(&:text).join("\n")
        method = MethodData.new(
          [namespace.id, "_self", "self", name].join(SEPARATOR),
          [namespace.id, "_self", "self"].join(SEPARATOR),
          name,
          [namespace.name, name].join("."),
          function_url,
          node.at_css(".sig.sig-object.py").text.match(/\((.*)\)/)&.[](1) || "",
          document,
        )
        @methods << method
      end
      class_nodes = parsed.css("dl.py.class")
      class_nodes.each do |node|
        # p node
        full_name = node.at_css("dt")["id"]
        namespace_name, name = full_name.rsplit(".", 2)
        namespace = @namespaces.find { |item| item.name == namespace_name }
        Console.info "  クラス#{name}を取得中..."
        function_url = url + node.at_css("a.headerlink")["href"]
        document_node = node.at_css("dd")
        document = parsed.css(document_node.css_path + "> p").map(&:text).join("\n")
        cls = ClassData.new(
          [namespace.id, name].join(SEPARATOR),
          namespace.id,
          name,
          [namespace.name, name].join("."),
          function_url,
          document,
        )
        @classes << cls
        attributes = node.parent.css(".py.attribute")
        attributes.each do |attr_node|
          name = attr_node.at_css(".sig-name.descname .pre").inner_text
          # Console.info "    属性#{name}を取得中..."
          attr_url = url + attr_node.at_css(".headerlink")["href"]
          document = parsed.css(attr_node.css_path + "> dd > p").map(&:text).join("\n")
          @attributes << AttributeData.new(
            [cls.id, "instance", name].join(SEPARATOR),
            [cls.id, "instance"].join(SEPARATOR),
            name,
            [namespace.name, cls.name, name].join("."),
            attr_url,
            document
          )
        end
        method_nodes = node.parent.css(".py.method")
        method_nodes.each do |meth_node|
          name = meth_node.at_css(".sig-name.descname .pre").inner_text
          # Console.info "    メソッド#{name}を取得中..."
          meth_url = url + meth_node.at_css(".headerlink")["href"]
          document = parsed.css(meth_node.css_path + "> dd > p").map(&:text).join("\n")
          property = meth_node.at_css("em.property")&.inner_text
          meth_type = if property&.include?("classmethod")
              "self"
            else
              "instance"
            end
          params = meth_node.at_css(".sig.sig-object.py").text.match(/\((.*)\)/)&.[](1)
          @methods << MethodData.new(
            [cls.id, meth_type, name].join(SEPARATOR),
            [cls.id, meth_type].join(SEPARATOR),
            name,
            [namespace.name, cls.name, name].join("."),
            meth_url,
            params || "",
            document
          )
        end
      end
    end
  end

  class << self
    attr_reader :urls
  end
end
