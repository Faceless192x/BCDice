# frozen_string_literal: true

module BCDice
  module GameSystem
    class Alsetto < Base
      # ゲームシステムの識別子
      ID = 'Alsetto'

      # ゲームシステム名
      NAME = '詩片のアルセット'

      # ゲームシステム名の読みがな
      SORT_KEY = 'うたかたのあるせつと'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~MESSAGETEXT
        ・成功判定：nAL[m]　　　　・トライアンフ無し：nALC[m]
        ・命中判定：nAL[m]*p　　　・トライアンフ無し：nALC[m]*p
        ・命中判定（ガンスリンガーの根源詩）：nALG[m]*p
        []内は省略可能。

        ALコマンドはトライアンフの分だけ、自動で振り足し処理を行います。
        「n」でダイス数を指定。
        「m」で目標値を指定。省略時は、デフォルトの「3」が使用されます。
        「p」で攻撃力を指定。「*」は「x」でも可。
        攻撃力指定で命中判定となり、成功数ではなく、ダメージを結果表示します。

        ALCコマンドはトライアンフ無しで、成功数、ダメージを結果表示します。
        ALGコマンドは「2以下」でトライアンフ処理を行います。

        【書式例】
        ・5AL → 5d6で目標値3。
        ・5ALC → 5d6で目標値3。トライアンフ無し。
        ・6AL2 → 6d6で目標値2。
        ・4AL*5 → 4d6で目標値3、攻撃力5の命中判定。
        ・7AL2x10 → 7d6で目標値2、攻撃力10の命中判定。
        ・8ALC4x5 → 8d6で目標値4、攻撃力5、トライアンフ無しの命中判定。
      MESSAGETEXT

      register_prefix('\d+AL[CG]?')

      def initialize(command)
        super(command)
        @sort_add_dice = true # ダイスのソート有
      end

      def eval_game_system_specific_command(command)
        # ALCコマンド：命中判定
        # ALCコマンド：成功判定
        if command =~ /(\d+)AL(C|G)?(\d+)?((x|\*)(\d+))?$/i
          rapid = Regexp.last_match(1).to_i
          is_critical = Regexp.last_match(2).nil?
          if is_critical
            critical_number = 1
          else
            if Regexp.last_match(2) == "G"
              is_critical = true
              critical_number = 2
            else
              critical_number = 0
            end
          end
          target = (Regexp.last_match(3) || 3).to_i
          damage = (Regexp.last_match(6) || 0).to_i
          return check_roll(rapid, target, damage, is_critical, critical_number)
        end

        return nil
      end

      def check_roll(rapid, target, damage, is_critical, critical_number)
        total_success_count = 0
        total_critical_count = 0
        text = ""

        roll_count = rapid

        while roll_count > 0
          dice_array = @randomizer.roll_barabara(roll_count, 6).sort
          dice_text = dice_array.join(",")

          success_count = 0
          critical_count = 0

          dice_array.each do |i|
            if i <= target
              success_count += 1
            end

            if i <= critical_number
              critical_count += 1
            end
          end

          total_success_count += success_count
          total_critical_count += 1 unless critical_count == 0

          text += "+" unless text.empty?
          text += "#{success_count}[#{dice_text}]"

          break unless is_critical

          roll_count = critical_count
        end

        is_damage = (damage != 0)

        if is_damage
          total_damage = total_success_count * damage

          result = "(#{rapid}D6\<\=#{target}) ＞ #{text} ＞ Hits：#{total_success_count}*#{damage} ＞ #{total_damage}ダメージ"
        else
          result = "(#{rapid}D6\<\=#{target}) ＞ #{text} ＞ 成功数：#{total_success_count}"
        end

        if is_critical
          result += " / #{total_critical_count}トライアンフ"
        end

        return result
      end
    end
  end
end
