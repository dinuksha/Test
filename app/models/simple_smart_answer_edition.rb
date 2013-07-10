require "edition"
require_relative 'simple_smart_answer_edition/node'
require_relative 'simple_smart_answer_edition/node/option'

class SimpleSmartAnswerEdition < Edition
  include Mongoid::Document

  field :body, type: String

  # We would use an embedded association to nodes here, however there is a
  # known issue with all versions of Mongoid where a conflict can arise on
  # save for documents with more than one level of embedded hierarchy and
  # which use nested attributes. For now, we're going to use a relational
  # association here.

  # This issue is already noted in the Mongoid GitHub repository.
  # https://github.com/mongoid/mongoid/issues/2989

  embeds_many :nodes, :class_name => "SimpleSmartAnswerEdition::Node"

  accepts_nested_attributes_for :nodes, allow_destroy: true

  GOVSPEAK_FIELDS = Edition::GOVSPEAK_FIELDS + [:body]
  @fields_to_clone = [:body]

  def whole_body
    body
  end

  def build_clone(edition_class=nil)
    new_edition = super(edition_class)
    new_edition.body = self.body

    if new_edition.is_a?(SimpleSmartAnswerEdition)
      self.nodes.each {|n| new_edition.nodes << n.clone }
    end

    new_edition
  end


  # Workaround mongoid conflicting mods error
  # See https://github.com/mongoid/mongoid/issues/1219
  # Override update_attributes so that nested nodes are updated individually. 
  # This get around the problem of mongoid issuing a query with conflicting modifications 
  # to the same document. 
  alias_method :original_update_attributes, :update_attributes
  
  def update_attributes(attributes)
    if nodes_attrs = attributes.delete(:nodes_attributes)
      nodes_attrs.each do |index, node_attrs|
        if node_id = node_attrs['id']
          node = nodes.find(node_id)
          if node_attrs["_destroy"] == '1'
            node.destroy
          else
            node.update_attributes(node_attrs)
          end
        else
          nodes << Node.new(node_attrs)
        end
      end
    end
    
    original_update_attributes(attributes)
  end

  def initial_node
    self.nodes.first
  end
end
