import 'dart:io';
import 'dart:math';

const int gridSize = 10;
const List<int> shipSizes = [4, 3, 3, 2, 2, 2, 1, 1, 1, 1];
const List<String> columnLabels = [
  'A',
  'B',
  'C',
  'D',
  'E',
  'F',
  'G',
  'H',
  'I',
  'J',
];

class SeaBattle {
  int playerHits = 0;
  int playerMisses = 0;
  int computerHits = 0;
  int computerMisses = 0;

  void clearScreen() {
    if (Platform.isWindows) {
      Process.runSync("cls", [], runInShell: true);
    } else {
      stdout.write('\x1B[2J\x1B[0;0H');
    }
  }

  void displayGrid(
    List<List<String>> grid, {
    bool showShips = false,
    List<List<bool>>? ships,
    String playerName = 'Компьютер',
  }) {
    clearScreen();
    print('\nПоле $playerName:');
    print('     A B C D E F G H I J');
    print('   ┌─────────────────────┐');
    for (int i = 0; i < gridSize; i++) {
      stdout.write('${(i + 1).toString().padLeft(2)} │');
      for (int j = 0; j < gridSize; j++) {
        if (showShips && ships != null && ships[i][j]) {
          stdout.write(' ■');
        } else {
          stdout.write(' ${grid[i][j]}');
        }
      }
      print(' │');
    }
    print('   └─────────────────────┘');
  }

  void placeShipsRandomly(List<List<bool>> shipGrid) {
    var rng = Random();
    for (var size in shipSizes) {
      bool placed = false;
      while (!placed) {
        int x = rng.nextInt(gridSize);
        int y = rng.nextInt(gridSize);
        bool horizontal = rng.nextBool();

        if (canPlaceShip(shipGrid, x, y, size, horizontal)) {
          for (int i = 0; i < size; i++) {
            if (horizontal) {
              shipGrid[x][y + i] = true;
            } else {
              shipGrid[x + i][y] = true;
            }
          }
          placed = true;
        }
      }
    }
  }

  bool canPlaceShip(
    List<List<bool>> grid,
    int x,
    int y,
    int size,
    bool horizontal,
  ) {
    if (horizontal && (y + size > gridSize)) return false;
    if (!horizontal && (x + size > gridSize)) return false;

    for (int i = -1; i <= size; i++) {
      for (int j = -1; j <= 1; j++) {
        int nx = horizontal ? x + j : x + i;
        int ny = horizontal ? y + i : y + j;
        if (nx >= 0 &&
            nx < gridSize &&
            ny >= 0 &&
            ny < gridSize &&
            grid[nx][ny]) {
          return false;
        }
      }
    }
    return true;
  }

  void placeShipsManually(List<List<bool>> shipGrid) {
    for (var size in shipSizes) {
      bool placed = false;
      while (!placed) {
        print('Введите координаты для корабля размером $size (например, A5):');
        String? input = stdin.readLineSync()?.toUpperCase();
        if (input == null || input.length < 2) {
          print('Неверный ввод, попробуйте снова.');
          continue;
        }
        int y = columnLabels.indexOf(input[0]);
        int x =
            int.tryParse(input.substring(1)) != null
                ? int.parse(input.substring(1)) - 1
                : -1;

        if (x < 0 || x >= gridSize || y < 0 || y >= gridSize) {
          print('Неверные координаты, попробуйте снова.');
          continue;
        }

        print('Выберите ориентацию: 1 - Горизонтально, 2 - Вертикально');
        String? choice = stdin.readLineSync();
        bool horizontal = choice == '1';

        if (canPlaceShip(shipGrid, x, y, size, horizontal)) {
          for (int i = 0; i < size; i++) {
            if (horizontal) {
              shipGrid[x][y + i] = true;
            } else {
              shipGrid[x + i][y] = true;
            }
          }
          placed = true;
          displayGrid(
            List.generate(gridSize, (_) => List.filled(gridSize, '·')),
            showShips: true,
            ships: shipGrid,
            playerName: 'Игрок',
          );
        } else {
          print('Невозможно разместить корабль, попробуйте снова.');
        }
      }
    }
  }

  void computerAttack(
    List<List<bool>> playerShips,
    List<List<String>> playerGrid,
  ) {
    var rng = Random();
    while (true) {
      int x = rng.nextInt(gridSize);
      int y = rng.nextInt(gridSize);

      if (playerGrid[x][y] == '·' || playerGrid[x][y] == '■') {
        if (playerShips[x][y]) {
          playerGrid[x][y] = '×';
          playerShips[x][y] = false;
          computerHits++;
          print('Компьютер попал в вашу клетку ($x, $y)!');
          if (isShipDestroyed(playerShips, x, y)) {
            print('Компьютер уничтожил ваш корабль!');
          } else {
            print('Компьютер ранил ваш корабль!');
          }
        } else {
          playerGrid[x][y] = '●';
          computerMisses++;
          print('Компьютер промахнулся!');
        }
        break;
      }
    }
  }

  bool isShipDestroyed(List<List<bool>> ships, int x, int y) {
    for (int i = -1; i <= 1; i++) {
      for (int j = -1; j <= 1; j++) {
        int nx = x + i;
        int ny = y + j;
        if (nx >= 0 &&
            nx < gridSize &&
            ny >= 0 &&
            ny < gridSize &&
            ships[nx][ny]) {
          return false;
        }
      }
    }
    return true;
  }

  int countRemainingShips(List<List<bool>> ships) {
    int count = 0;
    List<List<bool>> visited = List.generate(
      gridSize,
      (_) => List.filled(gridSize, false),
    );

    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        if (ships[i][j] && !visited[i][j]) {
          count++;
          markShipCells(ships, visited, i, j);
        }
      }
    }
    return count;
  }

  void markShipCells(
    List<List<bool>> ships,
    List<List<bool>> visited,
    int x,
    int y,
  ) {
    if (x < 0 ||
        x >= gridSize ||
        y < 0 ||
        y >= gridSize ||
        !ships[x][y] ||
        visited[x][y]) {
      return;
    }
    visited[x][y] = true;
    markShipCells(ships, visited, x + 1, y);
    markShipCells(ships, visited, x - 1, y);
    markShipCells(ships, visited, x, y + 1);
    markShipCells(ships, visited, x, y - 1);
  }

  void saveGameStats(
    String winner,
    int playerShipsDestroyed,
    int computerShipsDestroyed,
    int remainingShips,
  ) {
    final directory = Directory('game_stats');
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }

    final file = File('${directory.path}/game_stats.txt');
    final sink = file.openWrite(mode: FileMode.append);

    sink.writeln('Игра завершена: $winner');
    sink.writeln('Все корабли противника разрушены.');
    sink.writeln(
      'Осталось кораблей на поле: $remainingShips/${shipSizes.length * 2}',
    );
    sink.writeln('Игрок разрушил $playerShipsDestroyed кораблей.');
    sink.writeln(
      'Попадания игрока: $playerHits, Промахи игрока: $playerMisses',
    );
    sink.writeln('Компьютер разрушил $computerShipsDestroyed кораблей.');
    sink.writeln(
      'Попадания компьютера: $computerHits, Промахи компьютера: $computerMisses',
    );
    sink.writeln('---------------------------------------------------');

    sink.close();
  }

  void playSinglePlayer() {
    List<List<bool>> playerShips = List.generate(
      gridSize,
      (_) => List.filled(gridSize, false),
    );
    List<List<bool>> enemyShips = List.generate(
      gridSize,
      (_) => List.filled(gridSize, false),
    );
    List<List<String>> enemyGrid = List.generate(
      gridSize,
      (_) => List.filled(gridSize, '·'),
    );
    List<List<String>> playerGrid = List.generate(
      gridSize,
      (_) => List.filled(gridSize, '·'),
    );

    print('Выберите способ расстановки кораблей: 1 - Вручную, 2 - Рандомно');
    String? choice = stdin.readLineSync();
    if (choice == '1') {
      placeShipsManually(playerShips);
    } else {
      placeShipsRandomly(playerShips);
    }
    placeShipsRandomly(enemyShips);
    int enemyShipsRemaining = shipSizes.length;
    int playerShipsRemaining = shipSizes.length;

    while (enemyShipsRemaining > 0 && playerShipsRemaining > 0) {
      displayGrid(enemyGrid, showShips: false, playerName: 'Компьютер');
      print('Введите координаты для атаки (например, A5):');
      try {
        String? input = stdin.readLineSync()?.toUpperCase();
        if (input == null || input.length < 2) throw FormatException();
        int y = columnLabels.indexOf(input[0]);
        int x =
            int.tryParse(input.substring(1)) != null
                ? int.parse(input.substring(1)) - 1
                : -1;

        if (x < 0 || x >= gridSize || y < 0 || y >= gridSize) {
          print('Неверные координаты, попробуйте снова.');
          continue;
        }

        if (enemyShips[x][y]) {
          enemyGrid[x][y] = '×';
          enemyShips[x][y] = false;
          enemyShipsRemaining = countRemainingShips(enemyShips);
          playerHits++;
          print('Попадание!');
          if (isShipDestroyed(enemyShips, x, y)) {
            print('Вы уничтожили корабль противника!');
          } else {
            print('Вы ранили корабль противника!');
          }
        } else {
          enemyGrid[x][y] = '●';
          playerMisses++;
          print('Промах!');
        }
      } catch (e) {
        print('Ошибка ввода, попробуйте снова!');
        continue;
      }

      if (playerShipsRemaining > 0) {
        print('Ход компьютера:');
        computerAttack(playerShips, playerGrid);
        playerShipsRemaining = countRemainingShips(playerShips);
        displayGrid(
          playerGrid,
          showShips: true,
          ships: playerShips,
          playerName: 'Игрок',
        );
      }

      print('\nТекущий счет:');
      print('Игрок: $playerHits попаданий, $playerMisses промахов');
      print('Компьютер: $computerHits попаданий, $computerMisses промахов');
      print(
        'На поле осталось $enemyShipsRemaining/${shipSizes.length} кораблей противника.',
      );
      print(
        'На поле осталось $playerShipsRemaining/${shipSizes.length} ваших кораблей.',
      );
    }

    final remainingShips = enemyShipsRemaining + playerShipsRemaining;
    final playerShipsDestroyed = shipSizes.length - enemyShipsRemaining;
    final computerShipsDestroyed = shipSizes.length - playerShipsRemaining;

    if (enemyShipsRemaining == 0) {
      print('Поздравляем, вы победили!');
      saveGameStats(
        'Победа игрока',
        playerShipsDestroyed,
        computerShipsDestroyed,
        remainingShips,
      );
    } else {
      print('Компьютер победил!');
      saveGameStats(
        'Победа компьютера',
        playerShipsDestroyed,
        computerShipsDestroyed,
        remainingShips,
      );
    }
  }
}

void main() {
  SeaBattle game = SeaBattle();
  print(
    'Выберите режим игры: 1 - Против компьютера, 2 - Против другого игрока',
  );
  String? choice = stdin.readLineSync();
  if (choice == '1') {
    game.playSinglePlayer();
  } else if (choice == '2') {
    print('Режим для двух игроков пока не реализован.');
  } else {
    print('Неверный выбор.');
  }
}
