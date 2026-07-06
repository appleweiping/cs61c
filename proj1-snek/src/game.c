#include "game.h"

#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "snake_utils.h"

// The default board dimensions. These match asserts.c's DEFAULT_WIDTH /
// DEFAULT_BOARD_HEIGHT, but game.c is also linked into the `snake` executable
// (which does not link asserts.o), so we use local constants here.
#define DEFAULT_WIDTH 20
#define DEFAULT_HEIGHT 18

/* Helper function definitions */
static void set_board_at(game_t *game, unsigned int row, unsigned int col, char ch);
static bool is_tail(char c);
static bool is_head(char c);
static bool is_snake(char c);
static char body_to_tail(char c);
static char head_to_body(char c);
static unsigned int get_next_row(unsigned int cur_row, char c);
static unsigned int get_next_col(unsigned int cur_col, char c);
static void find_head(game_t *game, unsigned int snum);
static char next_square(game_t *game, unsigned int snum);
static void update_tail(game_t *game, unsigned int snum);
static void update_head(game_t *game, unsigned int snum);

/* Task 1 */
game_t *create_default_game() {
  game_t *game = malloc(sizeof(game_t));
  if (game == NULL) {
    return NULL;
  }

  game->num_rows = DEFAULT_HEIGHT;
  game->num_snakes = 1;

  game->board = malloc(game->num_rows * sizeof(char *));
  if (game->board == NULL) {
    free(game);
    return NULL;
  }

  // The default board is 18 rows tall and 20 columns wide. Each row string
  // stores 20 board characters, a trailing newline, and a null terminator.
  for (unsigned int row = 0; row < game->num_rows; row++) {
    game->board[row] = malloc((DEFAULT_WIDTH + 2) * sizeof(char));
    if (game->board[row] == NULL) {
      for (unsigned int r = 0; r < row; r++) {
        free(game->board[r]);
      }
      free(game->board);
      free(game);
      return NULL;
    }
    for (unsigned int col = 0; col < DEFAULT_WIDTH; col++) {
      if (row == 0 || row == game->num_rows - 1 || col == 0 || col == DEFAULT_WIDTH - 1) {
        game->board[row][col] = '#';
      } else {
        game->board[row][col] = ' ';
      }
    }
    game->board[row][DEFAULT_WIDTH] = '\n';
    game->board[row][DEFAULT_WIDTH + 1] = '\0';
  }

  // Place the single snake ("d>D") and a fruit ("*").
  game->board[2][2] = 'd';
  game->board[2][3] = '>';
  game->board[2][4] = 'D';
  game->board[2][9] = '*';

  game->snakes = malloc(game->num_snakes * sizeof(snake_t));
  if (game->snakes == NULL) {
    for (unsigned int r = 0; r < game->num_rows; r++) {
      free(game->board[r]);
    }
    free(game->board);
    free(game);
    return NULL;
  }
  game->snakes[0].tail_row = 2;
  game->snakes[0].tail_col = 2;
  game->snakes[0].head_row = 2;
  game->snakes[0].head_col = 4;
  game->snakes[0].live = true;

  return game;
}

/* Task 2 */
void free_game(game_t *game) {
  if (game == NULL) {
    return;
  }
  if (game->board != NULL) {
    for (unsigned int row = 0; row < game->num_rows; row++) {
      free(game->board[row]);
    }
    free(game->board);
  }
  free(game->snakes);
  free(game);
  return;
}

/* Task 3 */
void print_board(game_t *game, FILE *fp) {
  for (unsigned int row = 0; row < game->num_rows; row++) {
    fprintf(fp, "%s", game->board[row]);
  }
  return;
}

/*
  Saves the current game into filename. Does not modify the game object.
  (already implemented for you).
*/
void save_board(game_t *game, char *filename) {
  FILE *f = fopen(filename, "w");
  print_board(game, f);
  fclose(f);
}

/* Task 4.1 */

/*
  Helper function to get a character from the board
  (already implemented for you).
*/
char get_board_at(game_t *game, unsigned int row, unsigned int col) { return game->board[row][col]; }

/*
  Helper function to set a character on the board
  (already implemented for you).
*/
static void set_board_at(game_t *game, unsigned int row, unsigned int col, char ch) {
  game->board[row][col] = ch;
}

/*
  Returns true if c is part of the snake's tail.
  The snake consists of these characters: "wasd"
  Returns false otherwise.
*/
static bool is_tail(char c) {
  return c == 'w' || c == 'a' || c == 's' || c == 'd';
}

/*
  Returns true if c is part of the snake's head.
  The snake consists of these characters: "WASDx"
  Returns false otherwise.
*/
static bool is_head(char c) {
  return c == 'W' || c == 'A' || c == 'S' || c == 'D' || c == 'x';
}

/*
  Returns true if c is part of the snake.
  The snake consists of these characters: "wasd^<v>WASDx"
*/
static bool is_snake(char c) {
  return is_tail(c) || is_head(c) || c == '^' || c == '<' || c == 'v' || c == '>';
}

/*
  Converts a character in the snake's body ("^<v>")
  to the matching character representing the snake's
  tail ("wasd").
*/
static char body_to_tail(char c) {
  switch (c) {
    case '^':
      return 'w';
    case '<':
      return 'a';
    case 'v':
      return 's';
    case '>':
      return 'd';
    default:
      return '?';
  }
}

/*
  Converts a character in the snake's head ("WASD")
  to the matching character representing the snake's
  body ("^<v>").
*/
static char head_to_body(char c) {
  switch (c) {
    case 'W':
      return '^';
    case 'A':
      return '<';
    case 'S':
      return 'v';
    case 'D':
      return '>';
    default:
      return '?';
  }
}

/*
  Returns cur_row + 1 if c is 'v' or 's' or 'S'.
  Returns cur_row - 1 if c is '^' or 'w' or 'W'.
  Returns cur_row otherwise.
*/
static unsigned int get_next_row(unsigned int cur_row, char c) {
  if (c == 'v' || c == 's' || c == 'S') {
    return cur_row + 1;
  }
  if (c == '^' || c == 'w' || c == 'W') {
    return cur_row - 1;
  }
  return cur_row;
}

/*
  Returns cur_col + 1 if c is '>' or 'd' or 'D'.
  Returns cur_col - 1 if c is '<' or 'a' or 'A'.
  Returns cur_col otherwise.
*/
static unsigned int get_next_col(unsigned int cur_col, char c) {
  if (c == '>' || c == 'd' || c == 'D') {
    return cur_col + 1;
  }
  if (c == '<' || c == 'a' || c == 'A') {
    return cur_col - 1;
  }
  return cur_col;
}

/*
  Task 4.2

  Helper function for update_game. Return the character in the cell the snake is moving into.

  This function should not modify anything.
*/
static char next_square(game_t *game, unsigned int snum) {
  snake_t *snake = &game->snakes[snum];
  char head = get_board_at(game, snake->head_row, snake->head_col);
  unsigned int next_row = get_next_row(snake->head_row, head);
  unsigned int next_col = get_next_col(snake->head_col, head);
  return get_board_at(game, next_row, next_col);
}

/*
  Task 4.3

  Helper function for update_game. Update the head...

  ...on the board: add a character where the snake is moving

  ...in the snake struct: update the row and col of the head

  Note that this function ignores food, walls, and snake bodies when moving the head.
*/
static void update_head(game_t *game, unsigned int snum) {
  snake_t *snake = &game->snakes[snum];
  char head = get_board_at(game, snake->head_row, snake->head_col);
  unsigned int next_row = get_next_row(snake->head_row, head);
  unsigned int next_col = get_next_col(snake->head_col, head);

  // Convert the current head into a body segment, then place the head
  // one step forward in its direction of travel.
  set_board_at(game, snake->head_row, snake->head_col, head_to_body(head));
  set_board_at(game, next_row, next_col, head);

  snake->head_row = next_row;
  snake->head_col = next_col;
  return;
}

/*
  Task 4.4

  Helper function for update_game. Update the tail...

  ...on the board: blank out the current tail, and change the new
  tail from a body character (^<v>) into a tail character (wasd)

  ...in the snake struct: update the row and col of the tail
*/
static void update_tail(game_t *game, unsigned int snum) {
  snake_t *snake = &game->snakes[snum];
  char tail = get_board_at(game, snake->tail_row, snake->tail_col);
  unsigned int next_row = get_next_row(snake->tail_row, tail);
  unsigned int next_col = get_next_col(snake->tail_col, tail);

  // Erase the old tail, then promote the next body segment to be the new tail.
  set_board_at(game, snake->tail_row, snake->tail_col, ' ');
  char next = get_board_at(game, next_row, next_col);
  set_board_at(game, next_row, next_col, body_to_tail(next));

  snake->tail_row = next_row;
  snake->tail_col = next_col;
  return;
}

/* Task 4.5 */
void update_game(game_t *game, int (*add_food)(game_t *game)) {
  for (unsigned int snum = 0; snum < game->num_snakes; snum++) {
    snake_t *snake = &game->snakes[snum];
    if (!snake->live) {
      continue;
    }

    char target = next_square(game, snum);

    if (target == '#' || is_snake(target)) {
      // Collision: the snake dies and its head becomes an 'x'.
      set_board_at(game, snake->head_row, snake->head_col, 'x');
      snake->live = false;
    } else if (target == '*') {
      // Ate a fruit: the head advances but the tail stays, so the snake grows.
      update_head(game, snum);
      add_food(game);
    } else {
      // Empty square: move both head and tail forward.
      update_head(game, snum);
      update_tail(game, snum);
    }
  }
  return;
}

/* Task 5.1 */
char *read_line(FILE *fp) {
  size_t capacity = 16;
  size_t length = 0;
  char *line = malloc(capacity * sizeof(char));
  if (line == NULL) {
    return NULL;
  }

  int c;
  while ((c = fgetc(fp)) != EOF) {
    if (length + 1 >= capacity) {
      capacity *= 2;
      char *tmp = realloc(line, capacity * sizeof(char));
      if (tmp == NULL) {
        free(line);
        return NULL;
      }
      line = tmp;
    }
    line[length++] = (char)c;
    if (c == '\n') {
      break;
    }
  }

  if (length == 0 && c == EOF) {
    // Nothing was read and we hit end-of-file.
    free(line);
    return NULL;
  }

  // Shrink to the exact size needed (including the null terminator).
  char *result = realloc(line, (length + 1) * sizeof(char));
  if (result == NULL) {
    free(line);
    return NULL;
  }
  result[length] = '\0';
  return result;
}

/* Task 5.2 */
game_t *load_board(FILE *fp) {
  game_t *game = malloc(sizeof(game_t));
  if (game == NULL) {
    return NULL;
  }
  game->num_rows = 0;
  game->board = NULL;
  game->num_snakes = 0;
  game->snakes = NULL;

  char *line;
  while ((line = read_line(fp)) != NULL) {
    char **tmp = realloc(game->board, (game->num_rows + 1) * sizeof(char *));
    if (tmp == NULL) {
      free(line);
      free_game(game);
      return NULL;
    }
    game->board = tmp;
    game->board[game->num_rows] = line;
    game->num_rows++;
  }

  return game;
}

/*
  Task 6.1

  Helper function for initialize_snakes.
  Given a snake struct with the tail row and col filled in,
  trace through the board to find the head row and col, and
  fill in the head row and col in the struct.
*/
static void find_head(game_t *game, unsigned int snum) {
  snake_t *snake = &game->snakes[snum];
  unsigned int row = snake->tail_row;
  unsigned int col = snake->tail_col;
  char c = get_board_at(game, row, col);

  // Walk from the tail along body segments until we reach the head.
  while (!is_head(c)) {
    row = get_next_row(row, c);
    col = get_next_col(col, c);
    c = get_board_at(game, row, col);
  }

  snake->head_row = row;
  snake->head_col = col;
  return;
}

/* Task 6.2 */
game_t *initialize_snakes(game_t *game) {
  game->num_snakes = 0;
  game->snakes = NULL;

  for (unsigned int row = 0; row < game->num_rows; row++) {
    unsigned int col = 0;
    while (game->board[row][col] != '\0' && game->board[row][col] != '\n') {
      char c = game->board[row][col];
      if (is_tail(c)) {
        snake_t *tmp = realloc(game->snakes, (game->num_snakes + 1) * sizeof(snake_t));
        if (tmp == NULL) {
          return NULL;
        }
        game->snakes = tmp;
        game->snakes[game->num_snakes].tail_row = row;
        game->snakes[game->num_snakes].tail_col = col;
        game->snakes[game->num_snakes].live = true;
        find_head(game, game->num_snakes);
        game->num_snakes++;
      }
      col++;
    }
  }

  return game;
}
