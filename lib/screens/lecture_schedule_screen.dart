import 'package:flutter/material.dart';
import '../data/lecture_data.dart';

class LectureScheduleScreen extends StatefulWidget {
  final String roomName;

  const LectureScheduleScreen({required this.roomName, super.key});

  @override
  State<LectureScheduleScreen> createState() => _LectureScheduleScreenState();
}

class _LectureScheduleScreenState extends State<LectureScheduleScreen> {
  late String currentRoomName;
  final TextEditingController _controller = TextEditingController();

  final List<String> days = ['월', '화', '수', '목', '금'];
  final List<String> periods = [
    '0A', '0B', '1A', '1B', '2A', '2B', '3A', '3B',
    '4A', '4B', '5A', '5B', '6A', '6B', '7A', '7B',
    '8A', '8B', '9A', '9B', '10A', '10B', '11A', '11B',
    '12A', '12B', '13A', '13B', '14A', '14B', '15A', '15B',
  ];
  final List<String> timeText = [
    '08:00', '08:30', '09:00', '09:30', '10:00', '10:30',
    '11:00', '11:30', '12:00', '12:30', '13:00', '13:30',
    '14:00', '14:30', '15:00', '15:30', '16:00', '16:30',
    '17:00', '17:30', '18:00', '18:30', '19:00', '19:30',
    '20:00', '20:30', '21:00', '21:30', '22:00', '22:30',
    '23:00', '23:30',
  ];
  final Map<String, String> timeToPeriod = {};

  @override
  void initState() {
    super.initState();
    currentRoomName = widget.roomName;
    _controller.text = widget.roomName;

    // ⏱️ 시간 → 교시 문자열 매핑
    for (int i = 0; i < timeText.length; i++) {
      timeToPeriod[timeText[i]] = periods[i];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF004098),
        title: Text('$currentRoomName 강의실 시간표'),
      ),
      body: Column(
        children: [
          // 🔍 강의실 검색창
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: '강의실 번호를 입력하세요 (예: 3228)',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) {
                setState(() {
                  currentRoomName = value;
                });
              },
            ),
          ),
          // 📋 시간표 테이블
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: _buildMergedTimeTable(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMergedTimeTable() {
    final lectures = LectureDataManager.getLecturesForRoom(currentRoomName);

    // 🧱 시간표 테이블 초기화
    Map<String, Map<String, Map<String, dynamic>?>> table = {};
    for (var day in days) {
      table[day] = {};
      for (var period in periods) {
        table[day]![period] = null;
      }
    }

    // 📌 강의 정보 채우기
    for (var lecture in lectures) {
      String? day = lecture['day'];
      String? start = lecture['start'];
      String? end = lecture['end'];
      if (day == null || start == null || end == null) continue;

      String? startPeriod = timeToPeriod[start];
      String? endPeriod = timeToPeriod[end];
      if (startPeriod == null || endPeriod == null) continue;

      int startIdx = periods.indexOf(startPeriod);
      int endIdx = periods.indexOf(endPeriod);
      if (startIdx == -1 || endIdx == -1) continue;

      for (int i = startIdx; i <= endIdx; i++) {
        table[day]![periods[i]] = {
          'subject': lecture['subject'],
          'professor': lecture['professor'],
          'isStart': i == startIdx,
          'rowSpan': endIdx - startIdx + 1,
        };
      }
    }

    List<TableRow> rows = [];

    // 🗓️ 요일 헤더
    rows.add(
      TableRow(
        children: [
          Container(
            height: 50,
            alignment: Alignment.center,
            color: Colors.white,
            child: const Text('시간'),
          ),
          ...days.map(
            (day) => Container(
              height: 50,
              alignment: Alignment.center,
              color: const Color(0xFF7DA7D9),
              child: Text(
                day,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Set<String> rendered = {}; // 중복 렌더 방지용

    for (int i = 0; i < periods.length; i++) {
      List<Widget> rowCells = [];

      // ⏰ 왼쪽 시간 셀
      rowCells.add(
        Container(
          height: 40,
          alignment: Alignment.center,
          color: Colors.grey[100],
          child: Text(
            '${periods[i]}\n${timeText[i]}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10),
          ),
        ),
      );

      // 📅 각 요일별 셀
      for (var day in days) {
        String key = '$day-${periods[i]}';
        var cell = table[day]![periods[i]];

        if (rendered.contains(key)) {
          rowCells.add(const SizedBox.shrink());
          continue;
        }

        if (cell == null) {
          rowCells.add(Container(height: 40));
        } else if (cell['isStart'] == true) {
          int rowSpan = cell['rowSpan'];
          for (int r = 1; r < rowSpan; r++) {
            if (i + r < periods.length) {
              rendered.add('$day-${periods[i + r]}');
            }
          }

          rowCells.add(
            TableCell(
              verticalAlignment: TableCellVerticalAlignment.fill,
              child: Container(
                height: 40.0 * rowSpan,
                alignment: Alignment.center,
                color: const Color(0xFF7DA7D9),
                child: Text(
                  '${cell['subject']}\n${cell['professor']}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        } else {
          rowCells.add(Container(height: 40));
        }
      }

      rows.add(TableRow(children: rowCells));
    }

    return Table(
      border: TableBorder.all(color: Colors.grey),
      columnWidths: {
        0: const FixedColumnWidth(60),
        for (int i = 1; i <= days.length; i++) i: const FixedColumnWidth(80),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: rows,
    );
  }
}
