# typed: strict
# frozen_string_literal: true

require "cleaner"

class CleanerFactory
  # This just a PoC
  # rubocop:disable Homebrew/MoveToExtendOS
  CLEANER_CLASS = T.let(if OS.mac?
                          require "extend/os/mac/cleaner"
                          CleanerMac
                        elsif OS.linux?
                          require "extend/os/linux/cleaner"
                          CleanerLinux
                        else
                          Cleaner
  end.freeze, T.class_of(Cleaner))
  # rubocop:enable Homebrew/MoveToExtendOS

  sig { params(formula: Formula).returns(Cleaner) }
  def self.create(formula) = CLEANER_CLASS.new(formula)
end
