class Comment < ActiveRecord::Base
  include ActsAsCommentable::Comment
  include WithTimepointCounts
  before_destroy :mark_events_unlinkable

  belongs_to :user
  belongs_to :commentable, ->() { unscope(where: :deleted) }, polymorphic: true

  default_scope -> { order('created_at ASC') }

  alias_attribute :text, :comment

  def self.add(values, commenter, commentable)
    cmd = Actions::AddComment.new(values, commenter, commentable)
    cmd.perform
  end

  def extract_mentions
    cmd = Actions::ExtractMentions.new(self.text)
    cmd.perform
  end

  def extract_role_mentions
    cmd = Actions::ExtractRoleMentions.new(self.text)
    cmd.perform
  end

  private
  def mark_events_unlinkable
    if self.commentable.respond_to?(:events)
      unlinkable_events = self.commentable.events.where(action: 'commented')
        .select { |e| e.state_params['comment'] && e.state_params['comment']['id'] == self.id }
      unlinkable_events.each do |e|
        e.unlinkable = true
        e.save
      end
    end
  end
end
