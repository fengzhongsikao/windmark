import 'package:windmark/core/iching/hexagram.dart';
import 'package:windmark/core/iching/trigram.dart';

class HexagramEntry {
  const HexagramEntry({
    required this.number,
    required this.name,
    required this.upperName,
    required this.lowerName,
    required this.text,
  });

  final int number;
  final String name;
  final String upperName;
  final String lowerName;
  final String text;

  String get title {
    final upper = Trigram.byName(upperName);
    final lower = Trigram.byName(lowerName);
    if (upperName == lowerName) {
      return '$name为${upper.nature}';
    }
    return '${upper.nature}${lower.nature}$name';
  }

  Hexagram get hexagram {
    return Hexagram.fromTrigrams(
      Trigram.byName(lowerName),
      Trigram.byName(upperName),
    );
  }
}

abstract final class HexagramBook {
  static final List<HexagramEntry> entries = [
    for (var i = 0; i < _specs.length; i++)
      HexagramEntry(
        number: i + 1,
        name: _specs[i].name,
        upperName: _specs[i].upper,
        lowerName: _specs[i].lower,
        text: _specs[i].text,
      ),
  ];

  static final Map<String, HexagramEntry> _byPair = {
    for (final entry in entries) '${entry.upperName}${entry.lowerName}': entry,
  };

  static HexagramEntry of(Hexagram hexagram) {
    final entry = _byPair['${hexagram.upper.name}${hexagram.lower.name}'];
    if (entry == null) {
      throw StateError('卦表缺少 ${hexagram.upper.name}${hexagram.lower.name}');
    }
    return entry;
  }

  static HexagramEntry byNumber(int number) => entries[number - 1];

  static HexagramEntry daily(DateTime date) {
    final serial = date.year * 367 + date.month * 31 + date.day;
    return byNumber(serial % 64 + 1);
  }
}

class _Spec {
  const _Spec(this.name, this.upper, this.lower, this.text);

  final String name;
  final String upper;
  final String lower;
  final String text;
}

const _specs = <_Spec>[
  _Spec('乾', '乾', '乾', '刚健在内，适合主动开辟，步步为营，忌骄矜。'),
  _Spec('坤', '坤', '坤', '宜顺势包容，以柔成事。根基稳了，再谈展开。'),
  _Spec('屯', '坎', '震', '草创维艰。先稳住根基，找可靠的人商量，再图发展。'),
  _Spec('蒙', '艮', '坎', '事情还有不清楚的地方。宜请教、学习，不要凭感觉硬闯。'),
  _Spec('需', '坎', '乾', '时机未到。把准备做足，守正等待，比抢跑有利。'),
  _Spec('讼', '乾', '坎', '容易起争执。先把边界说清，能和则和，避免意气用事。'),
  _Spec('师', '坤', '坎', '需要纪律和带领。众人齐心、职责分明，事情才推得动。'),
  _Spec('比', '坎', '坤', '亲近正当、可靠的人。合作比独自硬扛更有利。'),
  _Spec('小畜', '巽', '乾', '已有小的积累，还没到大成。宜细水长流，继续蓄力。'),
  _Spec('履', '乾', '兑', '路上有分寸就要守住。按礼按约行事，险处也可以过去。'),
  _Spec('泰', '坤', '乾', '上下能够交流，时机比较顺。适合推进已经成熟的事。'),
  _Spec('否', '乾', '坤', '气机闭塞。先收缩、整顿内部，不宜强行向外扩张。'),
  _Spec('同人', '乾', '离', '志同可以共事。公开坦诚，比私下算计更能成事。'),
  _Spec('大有', '离', '乾', '所得已经不少。盛的时候更要节制，也要懂得分享。'),
  _Spec('谦', '坤', '艮', '谦退自持，反而容易招来助力。居功、争先都会减分。'),
  _Spec('豫', '震', '坤', '气氛顺畅，可以预备，也可以放松。不要因此松懈到底。'),
  _Spec('随', '兑', '震', '适合跟随时势和可靠的人。择善而从，不必事事自己开路。'),
  _Spec('蛊', '艮', '巽', '积下的问题该整理了。拖延会更重，宜修复，不宜粉饰。'),
  _Spec('临', '坤', '兑', '机会靠近。可以主动走近，同时把监督和关怀一起做。'),
  _Spec('观', '巽', '坤', '先观察再表态。看清局势，比急着出手重要。'),
  _Spec('噬嗑', '离', '震', '中间有阻碍，需要把是非讲明。含糊过去，后面还会卡。'),
  _Spec('贲', '艮', '离', '外表可以修饰，实质更要紧。文和质相称就够了。'),
  _Spec('剥', '艮', '坤', '属于消落的阶段。宜守不宜攻，先保住核心，等待恢复。'),
  _Spec('复', '坤', '震', '有重新开始的气象。从小处恢复，不必一下子铺开。'),
  _Spec('无妄', '乾', '震', '以诚对待，不存侥幸。没有根据的动作容易生出枝节。'),
  _Spec('大畜', '艮', '乾', '宜积蓄才干和资源。暂时收敛，厚积之后再发。'),
  _Spec('颐', '艮', '震', '留意自己靠什么滋养，也留意口舌。所说所依，都要择正。'),
  _Spec('大过', '兑', '巽', '负担偏重，寻常办法不够。要有人分担，也要有非常的安排。'),
  _Spec('坎', '坎', '坎', '重重险阻。用熟悉、诚信的方法一步步走，不要同时开太多线。'),
  _Spec('离', '离', '离', '宜依附光明和正当的依靠。把事情看清楚，前路才明。'),
  _Spec('咸', '兑', '艮', '彼此能够感应。适合沟通、亲近，真诚才有回应。'),
  _Spec('恒', '震', '巽', '宜建立可以持续的节奏。长久靠的是不改其志，不是一阵猛劲。'),
  _Spec('遁', '乾', '艮', '宜退守、避开锋芒。退不是失败，是把局面保住。'),
  _Spec('大壮', '震', '乾', '力量已经起来。用在正处才有益，忌仗着势强压人。'),
  _Spec('晋', '离', '坤', '如日升起来。适合展示成果，让该看见的人看见。'),
  _Spec('明夷', '坤', '离', '光明暂时被遮住。收敛锋芒，心里明白即可，不必外露。'),
  _Spec('家人', '巽', '离', '先安内部，再谈对外。各安其位，事情才顺。'),
  _Spec('睽', '离', '兑', '意见有分歧。求同存异，小事可通，大事宜缓。'),
  _Spec('蹇', '坎', '艮', '前路难行。停下来请教或绕路，比硬冲更合适。'),
  _Spec('解', '震', '坎', '困局有松开的迹象。抓住松动，把遗留问题处理掉。'),
  _Spec('损', '艮', '兑', '有所减损才能得益。放下次要的，保住关键的。'),
  _Spec('益', '巽', '震', '有得助力的气象。利人也能利己，适合推进合作。'),
  _Spec('夬', '兑', '乾', '到了该决断的时候。公开、果断，方式仍要正当。'),
  _Spec('姤', '乾', '巽', '会有不期而遇的接触。先辨清来意，再决定交往深浅。'),
  _Spec('萃', '兑', '坤', '人和资源会聚拢。需要一个核心，也需要秩序。'),
  _Spec('升', '坤', '巽', '可以循序上升。靠积累，不靠跳跃。'),
  _Spec('困', '兑', '坎', '言路或资源受困。守住该守的，向内找办法，少做空承诺。'),
  _Spec('井', '坎', '巽', '回到日常和根本的供给。修缮已有的，比另起炉灶合适。'),
  _Spec('革', '兑', '离', '到了该变革的时候。去旧布新之前，先取得相关的人信任。'),
  _Spec('鼎', '离', '巽', '适合立新的格局。重人和名实相符，事情才能成器。'),
  _Spec('震', '震', '震', '会有突然的震动。先稳住自己，惊过之后能反思，就有所得。'),
  _Spec('艮', '艮', '艮', '宜止、宜静。边界想清楚再动，停本身就是保护。'),
  _Spec('渐', '巽', '艮', '循序渐进。感情和事情都宜慢热，稳了才容易成。'),
  _Spec('归妹', '震', '兑', '名分和期待要谈清。情意热而位置不正，后面容易生悔。'),
  _Spec('丰', '震', '离', '处于盛的时候，宜把握眼前的光。过盛就要防遮蔽和松懈。'),
  _Spec('旅', '离', '艮', '身处客位。轻装、守礼、谨慎，途中就少大的过失。'),
  _Spec('巽', '巽', '巽', '以柔和的方式反复沟通。吩咐和心意要一致，才进得去。'),
  _Spec('兑', '兑', '兑', '和悦交流有利。高兴之外，原则仍要守住。'),
  _Spec('涣', '巽', '坎', '心力容易散。把分散的注意力收拢到一件关键事上。'),
  _Spec('节', '坎', '兑', '宜有节制和规矩。过与不及都不好，定一个可执行的限度。'),
  _Spec('中孚', '巽', '兑', '诚信能够感通。对内对外都宜说到做到。'),
  _Spec('小过', '震', '艮', '小事可为，大事不宜过度。低调度过，比高调强求好。'),
  _Spec('既济', '坎', '离', '事情大致已成。接下来是守成和收尾，防松懈。'),
  _Spec('未济', '离', '坎', '还没有完成。火候不够时，重新排顺序，再继续。'),
];
