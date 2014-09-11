
require 'sqlite3'
require 'active_record'

ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: 'hatena-blog-entry.sqlite'
)

unless ActiveRecord::Base.connection.table_exists? 'entries'
  ActiveRecord::Schema.define(version: 1) {
    create_table(:entries) {|t|
      t.string :title
      t.text :body
    }
  }
end

require 'elasticsearch/model'

class Entry < ActiveRecord::Base
  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks

  mapping do
    indexes :id, type: 'string', index: 'not_analyzed'
    indexes :title, type: 'string', analyzer: 'kuromoji'
    indexes :body, type: 'string', analyzer: 'kuromoji'
  end

  def more_like_this(mlt_fields: 'title,body', min_doc_freq: 0, min_term_freq: 0, min_word_len: 0, search_size: 10, body: {})
    target_id = self.id
    es = __elasticsearch__
    searcher = Class.new do
      define_method(:execute!) do
        es.client.mlt(
          search_size: search_size,
          index: es.index_name,
          type: es.document_type,
          body: body,
          id: target_id,
          mlt_fields: mlt_fields,
          min_doc_freq: min_doc_freq,
          min_term_freq: min_term_freq,
          min_word_len: min_word_len
        )
      end
    end.new
    Elasticsearch::Model::Response::Response.new(self.class, searcher)
  end
end

