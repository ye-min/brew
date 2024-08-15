# typed: strict
# frozen_string_literal: true

module CleanerLinux
  private

  sig { params(path: Pathname).returns(T::Boolean) }
  def executable_path?(path)
    path.elf? || path.text_executable?
  end
end

class Cleaner
  prepend CleanerLinux
end
