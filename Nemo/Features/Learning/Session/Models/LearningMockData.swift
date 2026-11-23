import SwiftUI

/// 学习会话离线 Mock 数据集
public enum LearningMockData {
    /// 示例单词单条数据（供单个组件 Preview 快速走查）
    public static var sampleWord: Word {
        mockWords[0]
    }

    /// 12 组带中日双语例句的真实高频日语词汇
    public static let mockWords: [Word] = [
        Word(
            id: 101,
            rawId: "word_101",
            japanese: "桜",
            hiragana: "さくら",
            chinese: "樱花",
            level: "N5",
            pos: "名词",
            example1: "春になると桜が一斉に咲き誇ります。",
            gloss1: "一到春天，樱花便竞相盛开。",
            example2: "公園で桜を見ながらお弁当を食べました。",
            gloss2: "在公园里一边赏樱一边吃了便当。",
            isDelisted: false
        ),
        Word(
            id: 102,
            rawId: "word_102",
            japanese: "木漏れ日",
            hiragana: "こもれび",
            chinese: "树叶缝隙透进来的阳光",
            level: "N1",
            pos: "名词",
            example1: "木漏れ日の中で静かに本を読む時間が好きです。",
            gloss1: "我喜欢在斑驳林荫下静心阅读的时光。",
            example2: "森の中を歩くと、柔らかな木漏れ日が差し込んできた。",
            gloss2: "在森林中散步时，柔和的阳光透过树叶洒了下来。",
            isDelisted: false
        ),
        Word(
            id: 103,
            rawId: "word_103",
            japanese: "勉強",
            hiragana: "べんきょう",
            chinese: "学习；钻研",
            level: "N5",
            pos: "名・他サ",
            example1: "毎日日本語の単語を熱心に勉強しています。",
            gloss1: "每天都在热心地学习日语单词。",
            example2: "図書館は静かで勉強に最適な環境です。",
            gloss2: "图书馆环境安静，最适合学习。",
            isDelisted: false
        ),
        Word(
            id: 104,
            rawId: "word_104",
            japanese: "約束",
            hiragana: "やくそく",
            chinese: "约定；诺言",
            level: "N4",
            pos: "名・他サ",
            example1: "友達と週末に映画を見に行く約束をしました。",
            gloss1: "和朋友约定周末一起去看电影。",
            example2: "一度交わした約束は必ず守らなければなりません。",
            gloss2: "一旦许下的承诺，就必须遵守。",
            isDelisted: false
        ),
        Word(
            id: 105,
            rawId: "word_105",
            japanese: "一期一会",
            hiragana: "いちごいちえ",
            chinese: "一生仅有一次的相会；珍惜每一次相遇",
            level: "N1",
            pos: "名词",
            example1: "茶道では一期一会の精神を大切にしています。",
            gloss1: "茶道极为重视一期一会的精神。",
            example2: "旅先での出会いはまさに一期一会です。",
            gloss2: "旅行途中的相逢，正是人生难得的机缘。",
            isDelisted: false
        ),
        Word(
            id: 106,
            rawId: "word_106",
            japanese: "感謝",
            hiragana: "かんしゃ",
            chinese: "感谢；感恩",
            level: "N3",
            pos: "名・自他サ",
            example1: "日頃の温かいご支援に心より感謝申し上げます。",
            gloss1: "对大家平日里的温暖支持表示由衷的感谢。",
            example2: "両親への感謝の気持ちを言葉にして伝えました。",
            gloss2: "将对父母的感激之情化作言语传递出来。",
            isDelisted: false
        ),
        Word(
            id: 107,
            rawId: "word_107",
            japanese: "雨宿り",
            hiragana: "あまやどり",
            chinese: "避雨；躲雨",
            level: "N2",
            pos: "名・自サ",
            example1: "急な夕立に見舞われ、駅の軒下で雨宿りをした。",
            gloss1: "遇到了突如其来的阵雨，便在车站屋檐下躲雨。",
            example2: "小さな喫茶店に入って雨宿りを兼ねて休憩した。",
            gloss2: "走进一家小咖啡馆，一边避雨一边休息。",
            isDelisted: false
        ),
        Word(
            id: 108,
            rawId: "word_108",
            japanese: "旅立ち",
            hiragana: "たびだち",
            chinese: "启程；踏上旅途；奔向新生活",
            level: "N2",
            pos: "名词",
            example1: "新しい夢に向かって、力強く旅立ちの時を迎えました。",
            gloss1: "奔向全新的梦想，迎来了充满力量的启程时刻。",
            example2: "故郷の駅で見送られながら旅立ちました。",
            gloss2: "在故乡车站众人的目送中踏上了旅程。",
            isDelisted: false
        ),
        Word(
            id: 109,
            rawId: "word_109",
            japanese: "微笑み",
            hiragana: "ほほえみ",
            chinese: "微笑",
            level: "N3",
            pos: "名词",
            example1: "彼女の優しい微笑みに心がとても温かくなりました。",
            gloss1: "她温柔的微笑让人的内心变得十分温暖。",
            example2: "赤ちゃんの無邪気な微笑みは周りを幸せにします。",
            gloss2: "婴儿纯真的微笑能让身边的人感到幸福。",
            isDelisted: false
        ),
        Word(
            id: 110,
            rawId: "word_110",
            japanese: "風鈴",
            hiragana: "ふうりん",
            chinese: "风铃",
            level: "N2",
            pos: "名词",
            example1: "夏の縁側で涼やかな風鈴の音が響いています。",
            gloss1: "夏日的走廊上传来风铃清脆悦耳的声响。",
            example2: "風が吹くたびに風鈴が心地よい音を奏でます。",
            gloss2: "每当微风吹拂，风铃便奏响宜人的音色。",
            isDelisted: false
        ),
        Word(
            id: 111,
            rawId: "word_111",
            japanese: "未来",
            hiragana: "みらい",
            chinese: "未来；将来",
            level: "N4",
            pos: "名词",
            example1: "明るい未来を信じて日々の努力を積み重ねています。",
            gloss1: "坚信美好的未来，每日坚持不断努力积累。",
            example2: "子どもたちの未来を守るために私たちができること。",
            gloss2: "为了守护孩子们的美好未来，我们所能做的事情。",
            isDelisted: false
        ),
        Word(
            id: 112,
            rawId: "word_112",
            japanese: "青空",
            hiragana: "あおぞら",
            chinese: "蓝天；晴空",
            level: "N4",
            pos: "名词",
            example1: "どこまでも澄み渡る青空を見上げて深呼吸をしました。",
            gloss1: "仰望一望无际的澄澈蓝天，深深地吸了一口气。",
            example2: "雨上がりの青空に美しい虹が架かりました。",
            gloss2: "雨过天晴的湛蓝天空中架起了一道美丽的彩虹。",
            isDelisted: false
        )
    ]

    /// 示例离线高频语法库
    public static let mockGrammars: [Grammar] = [
        Grammar(
            id: 201,
            rawId: "grammar_201",
            level: "N5",
            title: "～から～まで",
            content: GrammarContent(usages: [
                GrammarUsage(
                    subtype: "基本用法",
                    connection: "名詞 ＋ から ＋ 名詞 ＋ まで",
                    explanation: "表示时间或空间的起点和终点，意为“从……到……”。",
                    notes: "既可以表示空间起点终点，也可以表示时间起点终点。"
                )
            ]),
            isDelisted: false
        ),
        Grammar(
            id: 202,
            rawId: "grammar_202",
            level: "N4",
            title: "～てはいけない",
            content: GrammarContent(usages: [
                GrammarUsage(
                    subtype: "禁止表达",
                    connection: "動詞て形 ＋ はいけない",
                    explanation: "表示禁止做某事，相当于中文的“不能……”、“不可以……”。",
                    notes: "语气较为强硬，常用于规章制度、父母对子女或长辈对晚辈的告诫。"
                )
            ]),
            isDelisted: false
        ),
        Grammar(
            id: 203,
            rawId: "grammar_203",
            level: "N3",
            title: "～わけにはいかない",
            content: GrammarContent(usages: [
                GrammarUsage(
                    subtype: "情理限制",
                    connection: "動詞辞書形 / ない形 ＋ わけにはいかない",
                    explanation: "从社会常识、道德或心理情理上考虑，不能做某事或不得不做某事。",
                    notes: "与「～てはいけない」相比，更强调受制于人情、社会规则或内心责任感。"
                )
            ]),
            isDelisted: false
        ),
        Grammar(
            id: 204,
            rawId: "grammar_204",
            level: "N2",
            title: "～にほかならない",
            content: GrammarContent(usages: [
                GrammarUsage(
                    subtype: "断定强调",
                    connection: "名詞・動詞普通形 ＋ にほかならない",
                    explanation: "断定无二，相当于“无非是……”、“正是……”，用于郑重的书面表达。",
                    notes: "多用于论文、报道或正式演讲中阐述根本原因。"
                )
            ]),
            isDelisted: false
        ),
        Grammar(
            id: 205,
            rawId: "grammar_205",
            level: "N1",
            title: "～を皮切りに",
            content: GrammarContent(usages: [
                GrammarUsage(
                    subtype: "开端扩散",
                    connection: "名詞 ＋ を皮切りにして / を皮切りとして",
                    explanation: "以某事为开端，随后同类动作接二连三地展开。",
                    notes: "后续句多接连发生一系列规模逐渐扩大的积极事件。"
                )
            ]),
            isDelisted: false
        )
    ]

    /// 示例队列状态计数
    public static var mockQueueCounts: QueueCountState {
        QueueCountState(newCount: 6, learningCount: 2, reviewCount: 3, relearnCount: 1)
    }

    /// 示例结算战报统计
    public static var mockStats: LearningSessionStats {
        LearningSessionStats(
            totalLearnedCount: 12,
            newCount: 6,
            reviewCount: 4,
            relearnCount: 2,
            maxCombo: 8,
            durationSeconds: 154,
            dailyStreak: 12
        )
    }

    /// 示例 SRS 各档位复习间隔
    public static var mockRatingIntervals: [SRSRatingQuality: String] {
        [
            .again: "< 1m",
            .hard: "10m",
            .good: "1d",
            .easy: "4d"
        ]
    }
}

#Preview("Mock Data Inspection") {
    ZStack {
        Color.nemoGroupedBackground.ignoresSafeArea()

        VStack(spacing: 16) {
            Text("Mock 词库数量: \(LearningMockData.mockWords.count)")
                .font(.headline)
            Text("示例词汇: \(LearningMockData.sampleWord.japanese) (\(LearningMockData.sampleWord.hiragana))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
