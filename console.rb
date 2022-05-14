# frozen_string_literal: true

#
# 綺麗にログを出力するためのモジュール。
#
module Console
  module_function
  #
  # 警告ログを出力します。
  #
  # @param [#to_s] message メッセージ。
  #
  # @return [void]
  #
  def warn(message)
    puts "#{thread_kls}\e[93m!) \e[0m #{message}"
  end

  #
  # エラーログを出力します。
  #
  # @param [#to_s] message メッセージ。
  #
  # @return [void]
  #
  def error(message)
    puts "#{thread_kls}\e[91m×) \e[0m #{message}"
  end

  #
  # 情報ログを出力します。
  #
  # @param [#to_s] message メッセージ。
  #
  # @return [void]
  #
  def info(message)
    puts "#{thread_kls}\e[96mi) \e[0m #{message}"
  end

  #
  # 完了ログを出力します。
  #
  # @param [#to_s] message メッセージ。
  #
  # @return [void]
  #
  def success(message)
    puts "#{thread_kls}\e[92m✓) \e[0m #{message}"
  end

  #
  # 確認ログを出力します。
  #
  # @param [#to_s] message メッセージ。
  #
  # @return [void]
  #
  def ask(message)
    puts "#{thread_kls}\e[90m?) \e[0m #{message}"
  end

  def thread_kls
    kls = Thread.current[:kls]
    kls.color +
    kls.name.rjust(
      Fetcher.fetchers.filter_map(&:name).map(&:size).max,
      " "
    ) +
    " "
  end
end
