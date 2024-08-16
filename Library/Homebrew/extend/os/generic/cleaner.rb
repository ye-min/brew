# typed: strict
# frozen_string_literal: true

class Cleaner
  private

  sig { override.params(path: Pathname).returns(T::Boolean) }
  def executable_path?(path)
    path.text_executable? || path.executable?
  end
end
