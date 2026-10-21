class PurgeUnattachedBlobsJob < ApplicationJob
  queue_as :default

  def self.candidates(older_than: 1.day)
    ActiveStorage::Blob.unattached.where(created_at: ...older_than.ago)
  end

  def perform
    purged = 0
    self.class.candidates.find_each do |blob|
      blob.purge
      purged += 1
    end
    Rails.logger.info("[PurgeUnattachedBlobsJob] #{purged} blob(s) non rattaché(s) supprimé(s)")
  end
end
