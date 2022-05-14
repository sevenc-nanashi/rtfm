# frozen_string_literal: true
require "http"
require "nokogiri"
require "rsplit"

require_relative "base"

class Fetcher::RubydocInfo < Fetcher
  @color = "\e[41m"

  def fetch
    root_url = URI.parse(self.class.url)
    root_parsed = Nokogiri::HTML.parse(request_url(root_url))
    list_url = root_parsed.at_css("#nav")["src"]
    list_parsed = Nokogiri::HTML.parse(HTTP.get(root_url + list_url).to_s)
    class_nodes = list_parsed.css("#full_list li span.object_link a").select { |node|
      node["title"] != "Top Level Namespace (root)"
    }
    namespace_names = class_nodes.filter_map { |node|
      node["title"].sub(/ \(.+\)/, "")
    }.map { |name| name.rsplit("::", 2)[0] }.uniq
    [*namespace_names, ""].each do |name|
      @namespaces << NamespaceData.new(
        [self.class.library, name].join(SEPARATOR),
        name
      )
    end
    class_nodes.each do |node|
      cls_full_name = node["title"].split[0]
      namespace_name = cls_full_name.rsplit("::", 2)[-2] || ""
      cls_name = cls_full_name.rsplit("::", 2)[-1]
      namespace = @namespaces.find { |item| item.name == namespace_name }
      Console.info "  クラス#{cls_name}を取得中..."
      cls_url = root_url + node["href"]
      cls_parsed = Nokogiri::HTML.parse(request_url(cls_url))

      docstring = cls_parsed.css("h2").find { |node| node.text == "Overview" }&.next

      document = if docstring
          docstring.css(".discussion > p").map(&:text).join("\n")
        else
          ""
        end
      cls_data = ClassData.new(
        [namespace.id, cls_name].join(SEPARATOR),
        namespace.id,
        cls_name,
        [namespace.name, cls_name].join("::"),
        cls_url.to_s,
        document
      )
      @classes << cls_data

      cls_parsed.css("h2").find { |node|
        node.text.include? "Instance Attribute Summary"
      }&.next_element&.then do |attr_sum_node|
        attr_sum_node.css("li.public").each do |attr_node|
          attr_name = attr_node.at_css(".summary_signature strong").text
          attr_document = attr_node.css(".summary_desc p").map(&:text).join("\n")
          attr_aliases = attr_node.css(".summary_signature").text.match(
            /\(also: (.+)\)/
          )&.captures&.first&.split(", ")&.map { _1.sub("#", "") } || []
          [attr_name, *attr_aliases].each do |attr_alias|
            @attributes << AttributeData.new(
              [namespace.id, cls_name, "instance", attr_alias].join(SEPARATOR),
              [cls_data.id, "instance"].join(SEPARATOR),
              attr_alias,
              [namespace.name, cls_name].join("::") + "##{attr_alias}",
              (root_url + encode_href(attr_node.at_css(".summary_signature a")["href"])).to_s,
              attr_document
            )
          end
        end
      end

      cls_parsed.css("h2").find { |node|
        node.text.include? "Instance Method Summary"
      }&.next_element&.then do |meth_sum_node|
        meth_sum_node.css("li.public").each do |meth_node|
          meth_name = meth_node.at_css(".summary_signature strong").text
          meth_params = meth_node.at_css(".summary_signature").text.match(
            /\((.+)\)/
          )&.captures&.first
          meth_document = meth_node.css(".summary_desc p").map(&:text).join("\n")
          meth_aliases = meth_node.css(".summary_signature").text.match(
            /\(also: (.+)\)/
          )&.captures&.first&.split(", ")&.map { _1.sub("#", "") } || []
          [meth_name, *meth_aliases].each do |meth_alias|
            @methods << MethodData.new(
              [namespace.id, cls_name, "instance", meth_alias].join(SEPARATOR),
              [cls_data.id, "instance"].join(SEPARATOR),
              meth_alias,
              [namespace.name, cls_name].join("::") + "##{meth_alias}",
              (root_url + encode_href(meth_node.at_css(".summary_signature a")["href"])).to_s,
              meth_params,
              meth_document
            )
          end
        end
      end

      cls_parsed.css("h2").find { |node|
        node.text.include? "Class Method Summary"
      }&.next_element&.then do |meth_sum_node|
        meth_sum_node.css("li.public").each do |meth_node|
          meth_name = meth_node.at_css(".summary_signature strong").text
          meth_params = meth_node.at_css(".summary_signature").text.match(
            /\((.+)\)/
          )&.captures&.first
          meth_document = meth_node.css(".summary_desc p").map(&:text).join("\n")
          meth_aliases = meth_node.css(".summary_signature").text.match(
            /\(also: (.+)\)/
          )&.captures&.first&.split(", ")&.map { _1.sub(".", "") } || []
          [meth_name, *meth_aliases].each do |meth_alias|
            @methods << MethodData.new(
              [namespace.id, cls_name, "self", meth_alias].join(SEPARATOR),
              [cls_data.id, "self"].join(SEPARATOR),
              meth_alias,
              [namespace.name, cls_name].join("::") + ".#{meth_alias}",
              (root_url + encode_href(meth_node.at_css(".summary_signature a")["href"])).to_s,
              meth_params,
              meth_document
            )
          end
        end
      end
    end
  end

  def request_url(url)
    resp = HTTP.get(url)
    case resp.status
    when 202 # Generating
      Console.warn "  生成待機中..."
      sleep 1
      request_url(url)
    when 404
      raise "404 Not Found: #{url}"
    else
      return resp.to_s
    end
  end

  def encode_href(href)
    path, hash = href.split("#")
    path + "#" + URI.encode_www_form_component(hash)
  end
end
