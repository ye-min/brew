# typed: strict
# frozen_string_literal: true

class CleanerMac < Cleaner
  private

  sig { override.params(path: Pathname).returns(T::Boolean) }
  def executable_path?(path)
    path.mach_o_executable? || path.text_executable?
  end
end
