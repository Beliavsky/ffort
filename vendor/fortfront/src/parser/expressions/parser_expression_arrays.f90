module parser_expression_arrays_module
    use, intrinsic :: iso_fortran_env, only: int64
    use lexer_core, only: token_t, TK_OPERATOR, TK_IDENTIFIER, TK_KEYWORD, &
        TK_NEWLINE, TK_COMMENT
    use parser_state_module, only: parser_state_t
    use ast_arena_modern, only: ast_arena_t
    use ast_nodes_core, only: call_or_subscript_node, component_access_node, &
                              identifier_node, literal_node, binary_op_node, assignment_node
    use ast_nodes_bounds, only: range_expression_node, array_bounds_node
    use ast_base, only: LITERAL_INTEGER, LITERAL_STRING
    use ast_factory_control, only: push_do_loop
    use ast_factory_core, only: push_array_literal
    use ast_factory_expressions, only: push_call_or_subscript_with_slice_detection
    use ast_factory_arrays, only: push_array_slice
    use ast_factory_core, only: push_literal
    implicit none
    private

    abstract interface
        recursive integer function parse_expr_proc(parser, arena)
            import :: parser_state_t, ast_arena_t
            type(parser_state_t), intent(inout) :: parser
            type(ast_arena_t), intent(inout) :: arena
        end function parse_expr_proc
    end interface

    type :: array_parse_helpers_t
        procedure(parse_expr_proc), pointer, nopass :: parse_comparison => null()
        procedure(parse_expr_proc), pointer, nopass :: parse_unary => null()
        procedure(parse_expr_proc), pointer, nopass :: parse_logical_eqv => null()
        procedure(parse_expr_proc), pointer, nopass :: parse_range => null()
    end type array_parse_helpers_t

    public :: array_parse_helpers_t
    public :: parse_modern_array_literal
    public :: parse_legacy_array_literal
    public :: parse_array_indexing_postfix
    public :: parse_square_indexing_postfix

contains

    recursive function parse_legacy_array_literal(parser, arena, helpers) &
            result(expr_index)
        type(parser_state_t), intent(inout) :: parser
        type(ast_arena_t), intent(inout) :: arena
        type(array_parse_helpers_t), intent(in) :: helpers
        integer :: expr_index
        type(token_t) :: start_token, token

        start_token = parser%consume()
        token = parser%consume() ! Opening slash, checked by the caller.
        expr_index = parse_constructor_items(parser, arena, helpers, &
            start_token, "legacy", "/")
        if (expr_index <= 0) return
        token = parser%peek()
        if (.not. is_array_operator(token, ")")) then
            call parser%error_at_token("Expected ')' after array constructor '/'", token)
            expr_index = 0
            return
        end if
        token = parser%consume()
    end function parse_legacy_array_literal

    recursive function parse_modern_array_literal(parser, arena, start_token, &
            helpers) result(expr_index)
        type(parser_state_t), intent(inout) :: parser
        type(ast_arena_t), intent(inout) :: arena
        type(token_t), intent(in) :: start_token
        type(array_parse_helpers_t), intent(in) :: helpers
        integer :: expr_index

        expr_index = parse_constructor_items(parser, arena, helpers, &
            start_token, "modern", "]")
    end function parse_modern_array_literal

    ! Both spellings use exactly the same ac-value list grammar. An implied-DO
    ! is one list item, not an alternate parser for the entire constructor.
    recursive function parse_constructor_items(parser, arena, helpers, &
            start_token, style, terminator) result(expr_index)
        type(parser_state_t), intent(inout) :: parser
        type(ast_arena_t), intent(inout) :: arena
        type(array_parse_helpers_t), intent(in) :: helpers
        type(token_t), intent(in) :: start_token
        character(len=*), intent(in) :: style, terminator
        integer :: expr_index, item_index, count
        integer, allocatable :: items(:)
        character(len=:), allocatable :: type_spec
        type(token_t) :: token

        expr_index = 0
        if (.not. associated(helpers%parse_comparison)) return
        call skip_constructor_trivia(parser)
        call parse_constructor_type_spec(parser, type_spec)
        call skip_constructor_trivia(parser)
        allocate (items(20))
        count = 0
        token = parser%peek()
        if (is_array_operator(token, terminator)) then
            token = parser%consume()
        else
            do
                item_index = parse_constructor_item(parser, arena, helpers)
                if (item_index <= 0) return
                call append_constructor_item(items, count, item_index)
                call skip_constructor_trivia(parser)
                token = parser%peek()
                if (is_array_operator(token, terminator)) then
                    token = parser%consume()
                    exit
                end if
                if (.not. is_array_operator(token, ",")) then
                    call parser%error_at_token("Expected ',' or array constructor end", token)
                    return
                end if
                token = parser%consume()
                call skip_constructor_trivia(parser)
                token = parser%peek()
                if (is_array_operator(token, terminator) .or. parser%is_at_end()) then
                    call parser%error_at_token("Expected array constructor item after ','", token)
                    return
                end if
                if (count >= 100000) then
                    call parser%error("Too many array constructor items")
                    return
                end if
            end do
        end if
        if (len(type_spec) > 0) then
            expr_index = push_array_literal(arena, items(:count), &
                start_token%line, start_token%column, syntax_style=style, &
                type_spec=type_spec)
        else
            expr_index = push_array_literal(arena, items(:count), &
                start_token%line, start_token%column, syntax_style=style)
        end if
    end function parse_constructor_items

    ! Look ahead for a type-spec without constructing expression nodes. This
    ! also bounds malformed, unterminated type parameter lists at end of input.
    subroutine parse_constructor_type_spec(parser, type_spec)
        type(parser_state_t), intent(inout) :: parser
        character(len=:), allocatable, intent(out) :: type_spec
        type(token_t) :: token
        integer :: pos, depth, end_pos, i

        type_spec = ""
        token = parser%peek()
        if (token%kind /= TK_IDENTIFIER .and. token%kind /= TK_KEYWORD) return
        pos = parser%current_token + 1
        depth = 0
        end_pos = 0
        do while (pos <= parser%get_token_count())
            token = parser%get_token_at_index(pos)
            if (is_array_operator(token, "(")) then
                depth = depth + 1
            else if (is_array_operator(token, ")")) then
                if (depth == 0) return
                depth = depth - 1
            else if (depth == 0) then
                if (is_array_operator(token, "::")) end_pos = pos
                exit
            end if
            pos = pos + 1
        end do
        if (end_pos == 0) return
        do i = parser%current_token, end_pos - 1
            token = parser%get_token_at_index(i)
            type_spec = type_spec // token%text
        end do
        parser%current_token = end_pos + 1
    end subroutine parse_constructor_type_spec

    subroutine skip_constructor_trivia(parser)
        type(parser_state_t), intent(inout) :: parser
        type(token_t) :: token
        do
            token = parser%peek()
            if (token%kind /= TK_NEWLINE .and. token%kind /= TK_COMMENT) return
            token = parser%consume()
        end do
    end subroutine skip_constructor_trivia

    pure logical function is_array_operator(token, text) result(matches)
        type(token_t), intent(in) :: token
        character(len=*), intent(in) :: text
        matches = token%kind == TK_OPERATOR .and. token%text == text
    end function is_array_operator

    subroutine append_constructor_item(items, count, item)
        integer, allocatable, intent(inout) :: items(:)
        integer, intent(inout) :: count
        integer, intent(in) :: item
        integer, allocatable :: grown(:)
        if (count == size(items)) then
            allocate (grown(max(20, 2 * size(items))))
            grown(:count) = items
            call move_alloc(grown, items)
        end if
        count = count + 1
        items(count) = item
    end subroutine append_constructor_item

    ! Do not speculatively parse the opening slash of a nested legacy array
    ! constructor as an implied-do expression. A failed speculative parse can
    ! leave a binary node with a missing left operand in the arena even when
    ! the subsequent array parse succeeds.
    logical function is_legacy_array_item(parser) result(legacy)
        type(parser_state_t), intent(inout) :: parser
        type(token_t) :: token
        token = parser%get_token_at_index(parser%current_token + 1)
        legacy = token%kind == TK_OPERATOR .and. token%text == "/"
    end function is_legacy_array_item

    ! F2018 R770: an ac-value that starts with "(" is either a parenthesised
    ! expression, a complex literal (exactly two items), or an ac-implied-do
    ! (which carries "=" for its do-variable). A parenthesised list of three or
    ! more items without "=" matches none of those, so reject it here instead of
    ! letting the fallback expression parser swallow part of it.
    logical function is_malformed_parenthesized_item(parser) result(malformed)
        type(parser_state_t), intent(inout) :: parser
        type(token_t) :: open_paren
        type(token_t) :: token
        integer :: pos, depth, item_count
        logical :: has_equals

        malformed = .false.
        open_paren = parser%peek()
        if (open_paren%kind /= TK_OPERATOR) return
        if (open_paren%text /= "(") return

        ! An old-style array constructor `(/ ... /)` nested as an ac-value
        ! opens with the same "(" but is not a parenthesised item.
        token = parser%get_token_at_index(parser%current_token + 1)
        if (token%kind == TK_OPERATOR) then
            if (token%text == "/") return
        end if

        pos = parser%current_token + 1
        depth = 1
        item_count = 1
        has_equals = .false.

        do while (pos <= parser%get_token_count())
            token = parser%get_token_at_index(pos)
            if (token%kind == TK_OPERATOR) then
                select case (token%text)
                case ("(", "[")
                    depth = depth + 1
                case (")", "]")
                    depth = depth - 1
                    if (depth == 0) exit
                case (",")
                    if (depth == 1) item_count = item_count + 1
                case ("=")
                    if (depth == 1) has_equals = .true.
                end select
            end if
            pos = pos + 1
        end do

        if (depth /= 0) return
        if (has_equals) return
        if (item_count < 3) return

        malformed = .true.
        call parser%error_at_token( &
            "Syntax error in COMPLEX constant: a parenthesised array "// &
            "constructor item needs exactly two parts, or an implied-do "// &
            "with a do-variable", open_paren)
    end function is_malformed_parenthesized_item

    recursive function parse_constructor_item(parser, arena, helpers) &
            result(expr_index)
        type(parser_state_t), intent(inout) :: parser
        type(ast_arena_t), intent(inout) :: arena
        type(array_parse_helpers_t), intent(in) :: helpers
        integer :: expr_index
        type(token_t) :: token

        expr_index = 0
        call skip_constructor_trivia(parser)
        token = parser%peek()
        if (is_array_operator(token, "(")) then
            if (.not. is_legacy_array_item(parser)) then
                if (is_malformed_parenthesized_item(parser)) return
                if (is_constructor_implied_do(parser)) then
                    expr_index = parse_constructor_implied_do(parser, arena, helpers)
                    return
                end if
            end if
        end if
        expr_index = helpers%parse_comparison(parser, arena)
        if (expr_index <= 0) call parser%error("Expected array constructor expression")
    end function parse_constructor_item

    ! A top-level '=' distinguishes ac-implied-do from a grouped expression
    ! or complex literal. Nested keyword arguments and quoted punctuation do
    ! not participate. Classify before parsing, so failure leaves no orphan
    ! speculative expression tree and malformed iterators cannot fall back.
    logical function is_constructor_implied_do(parser) result(implied)
        type(parser_state_t), intent(in) :: parser
        type(token_t) :: token
        integer :: pos, depth
        implied = .false.
        depth = 1
        do pos = parser%current_token + 1, parser%get_token_count()
            token = parser%get_token_at_index(pos)
            if (token%kind /= TK_OPERATOR) cycle
            select case (token%text)
            case ("(", "[")
                depth = depth + 1
            case (")", "]")
                depth = depth - 1
                if (depth == 0) return
            case ("=")
                if (depth == 1) then
                    implied = .true.
                    return
                end if
            end select
        end do
    end function is_constructor_implied_do

    recursive function parse_constructor_implied_do(parser, arena, helpers) &
            result(expr_index)
        type(parser_state_t), intent(inout) :: parser
        type(ast_arena_t), intent(inout) :: arena
        type(array_parse_helpers_t), intent(in) :: helpers
        integer :: expr_index, body_index, count, start_index, end_index, step_index
        integer, allocatable :: body(:)
        character(len=:), allocatable :: var_name
        type(token_t) :: open_token, token, next_token

        expr_index = 0
        open_token = parser%consume()
        allocate (body(20))
        count = 0
        do
            body_index = parse_constructor_item(parser, arena, helpers)
            if (body_index <= 0) return
            call append_constructor_item(body, count, body_index)
            call skip_constructor_trivia(parser)
            token = parser%peek()
            if (.not. is_array_operator(token, ",")) then
                call parser%error_at_token("Expected ',' before implied-DO control", token)
                return
            end if
            token = parser%consume()
            call skip_constructor_trivia(parser)
            token = parser%peek()
            next_token = parser%get_token_at_index(parser%current_token + 1)
            if (token%kind == TK_IDENTIFIER .or. token%kind == TK_KEYWORD) then
                if (is_array_operator(next_token, "=")) exit
            end if
            if (count >= 100000 .or. parser%is_at_end()) then
                call parser%error("Expected implied-DO control variable")
                return
            end if
        end do
        var_name = token%text
        token = parser%consume()
        token = parser%consume() ! '='
        start_index = helpers%parse_comparison(parser, arena)
        if (start_index <= 0) then
            call parser%error("Syntax error in iterator: expected an initial bound expression")
            return
        end if
        call skip_constructor_trivia(parser)
        token = parser%peek()
        if (.not. is_array_operator(token, ",")) then
            call parser%error_at_token( &
                "Syntax error in iterator: expected ',' after initial bound", token)
            return
        end if
        token = parser%consume()
        end_index = helpers%parse_comparison(parser, arena)
        if (end_index <= 0) then
            call parser%error("Syntax error in iterator: expected a terminal bound expression")
            return
        end if
        step_index = 0
        call skip_constructor_trivia(parser)
        token = parser%peek()
        if (is_array_operator(token, ",")) then
            token = parser%consume()
            step_index = helpers%parse_comparison(parser, arena)
            if (step_index <= 0) then
                call parser%error("Syntax error in iterator: expected a stride expression")
                return
            end if
            call skip_constructor_trivia(parser)
            token = parser%peek()
        end if
        if (.not. is_array_operator(token, ")")) then
            call parser%error_at_token("Syntax error in iterator: expected ')'", token)
            return
        end if
        token = parser%consume()
        expr_index = push_do_loop(arena, var_name, start_index, end_index, &
            step_index=step_index, body_indices=body(:count), &
            line=open_token%line, column=open_token%column)
    end function parse_constructor_implied_do

    recursive function parse_array_indexing_postfix(parser, arena, base_expr, helpers) &
            result(expr_index)
        type(parser_state_t), intent(inout) :: parser
        type(ast_arena_t), intent(inout) :: arena
        integer, intent(in) :: base_expr
        type(array_parse_helpers_t), intent(in) :: helpers
        integer :: expr_index
        expr_index = apply_index_postfix(parser, arena, base_expr, helpers, ")")
    end function parse_array_indexing_postfix

    function parse_square_indexing_postfix(parser, arena, base_expr, helpers) &
            result(expr_index)
        type(parser_state_t), intent(inout) :: parser
        type(ast_arena_t), intent(inout) :: arena
        integer, intent(in) :: base_expr
        type(array_parse_helpers_t), intent(in) :: helpers
        integer :: expr_index
        expr_index = apply_index_postfix(parser, arena, base_expr, helpers, "]")
    end function parse_square_indexing_postfix

    recursive function apply_index_postfix(parser, arena, base_expr, helpers, &
                                           closing_char) result(expr_index)
        type(parser_state_t), intent(inout) :: parser
        type(ast_arena_t), intent(inout) :: arena
        integer, intent(in) :: base_expr
        type(array_parse_helpers_t), intent(in) :: helpers
        character(len=*), intent(in) :: closing_char
        integer :: expr_index
        type(token_t) :: open_token, close_token
        integer, allocatable :: arg_indices(:)
        character(len=:), allocatable :: call_name
        integer :: base_expr_for_call, open_token_index

        expr_index = base_expr
        if (.not. associated(helpers%parse_range)) return
        open_token_index = parser%current_token
        open_token = parser%consume()

        call collect_index_arguments(parser, arena, helpers, closing_char, &
            arg_indices, close_token)
        if (.not. allocated(arg_indices)) return

        call extract_target_name(arena, expr_index, call_name)
        if (.not. allocated(call_name)) then
            if (base_expr > 0 .and. base_expr <= arena%size) then
                expr_index = fold_literal_substring(parser, arena, base_expr, &
                                             arg_indices, open_token_index, close_token)
                if (expr_index == 0) then
                    expr_index = base_expr
                    if (any_range_argument(arena, arg_indices)) then
                        expr_index = push_array_slice(arena, base_expr, &
                                     arg_indices, size(arg_indices), close_token%line, &
                                                      close_token%column)
                    end if
                end if
            end if
            return
        end if

        ! Preserve a compound designator when this postfix contains a range.
        ! In particular, c(2)(1:3) must keep c(2) as the slice base instead of
        ! flattening back to the spelling c; otherwise the range is orphaned
        ! and the frontend silently lowers the whole array element. A plain
        ! identifier/literal remains a normal call/subscript: ffc uses
        ! base_expr_index for derived-component access, so setting it on c(1)
        ! would misclassify an ordinary character-array element.
        base_expr_for_call = 0
        if (base_expr > 0 .and. base_expr <= arena%size) then
            if (allocated(arena%entries(base_expr)%node)) then
                select type (base_node => arena%entries(base_expr)%node)
                    type is (component_access_node)
                    base_expr_for_call = base_expr
                    type is (call_or_subscript_node)
                    base_expr_for_call = base_expr
                end select
            end if
        end if

        expr_index = push_call_or_subscript_with_slice_detection( &
            arena, call_name, arg_indices, close_token%line, &
            close_token%column, base_expr_index=base_expr_for_call)
    end function apply_index_postfix

    recursive subroutine collect_index_arguments(parser, arena, helpers, closing_char, &
            arg_indices, close_token)
        type(parser_state_t), intent(inout) :: parser
        type(ast_arena_t), intent(inout) :: arena
        type(array_parse_helpers_t), intent(in) :: helpers
        character(len=*), intent(in) :: closing_char
        integer, allocatable, intent(out) :: arg_indices(:)
        type(token_t), intent(out) :: close_token
        type(token_t) :: token
        integer :: arg_index
        integer :: arg_count, i
        integer, parameter :: MAX_ARGUMENTS = 10000

        if (parser%is_at_end()) then
            close_token = parser%peek()
            return
        end if

        token = parser%peek()
        if (token%kind /= TK_OPERATOR .or. token%text /= closing_char) then
            arg_index = helpers%parse_range(parser, arena)
            if (arg_index > 0) then
                allocate (arg_indices(1))
                arg_indices(1) = arg_index
                arg_count = 1

                do while (arg_count < MAX_ARGUMENTS)
                    arg_count = arg_count + 1
                    token = parser%peek()
                    if (token%kind /= TK_OPERATOR .or. token%text /= ",") exit
                    token = parser%consume()
                    arg_index = helpers%parse_range(parser, arena)
                    if (arg_index > 0) then
                        arg_indices = [arg_indices, arg_index]
                    else
                        exit
                    end if
                end do
            end if
        end if

        token = parser%peek()
        if (token%kind == TK_OPERATOR .and. token%text == closing_char) then
            close_token = parser%consume()
        else
            close_token = token
        end if

        if (.not. allocated(arg_indices)) then
            allocate (arg_indices(0))
        end if
        ! Function/intrinsic actuals use the same assignment wrappers as CALL.
        ! A keyword label is not an assignment target or a variable reference.
        if (closing_char == ")") then
            do i = 1, size(arg_indices)
                if (.not. arena%has_node_at(arg_indices(i))) cycle
                select type (arg => arena%entries(arg_indices(i))%node)
                type is (assignment_node)
                    arg%is_keyword_argument = .true.
                end select
            end do
        end if
    end subroutine collect_index_arguments

    integer function fold_literal_substring(parser, arena, base_expr, arg_indices, &
                                           open_token_index, close_token) result(folded)
        type(parser_state_t), intent(inout) :: parser
        type(ast_arena_t), intent(inout) :: arena
        integer, intent(in) :: base_expr
        integer, intent(in) :: arg_indices(:)
        integer, intent(in) :: open_token_index
        type(token_t), intent(in) :: close_token
        type(token_t) :: source_token, token
        character(len=:), allocatable :: text, inner
        integer(int64) :: lo, up
        integer :: inner_len, i, lower_index, upper_index, depth, colons, commas
        character :: quote
        logical :: wrong_type, escaped, lower_known, upper_known

        folded = 0
        if (.not. arena%has_node_at(base_expr)) return
        select type (base => arena%entries(base_expr)%node)
        type is (literal_node)
            if (base%literal_kind /= LITERAL_STRING) return
            if (.not. allocated(base%value)) return
            text = base%value
            if (len(text) < 2) return
            quote = text(1:1)
            if (quote /= "'" .and. quote /= '"') return
            if (text(len(text):len(text)) /= quote) return
            inner = text(2:len(text) - 1)
            do i = 1, len(inner)
                if (iachar(inner(i:i)) > 127) return
            end do
        class default
            return
        end select

        source_token = parser%get_token_at_index(open_token_index)
        if (source_token%text /= '(' .or. close_token%text /= ')') then
            call parser%error_at_token( &
                'Invalid literal substring: expected a closing parenthesis', &
                source_token)
            return
        end if
        if (size(arg_indices) /= 1) then
            call parser%error_at_token( &
                'Invalid literal substring: expected one lower:upper range', &
                source_token)
            return
        end if
        colons = 0
        commas = 0
        depth = 0
        do i = open_token_index + 1, parser%current_token - 2
            token = parser%get_token_at_index(i)
            if (token%kind /= TK_OPERATOR) cycle
            select case (token%text)
            case ('(', '[')
                depth = depth + 1
            case (')', ']')
                depth = depth - 1
            case (':')
                if (depth == 0) colons = colons + 1
            case ('::')
                if (depth == 0) colons = colons + 2
            case (',')
                if (depth == 0) commas = commas + 1
            end select
        end do
        if (colons /= 1 .or. commas > 0) then
            call parser%error_at_token( &
                'Invalid literal substring: expected one complete lower:upper range', &
                source_token)
            return
        end if
        if (.not. arena%has_node_at(arg_indices(1))) return
        select type (rng => arena%entries(arg_indices(1))%node)
        type is (range_expression_node)
            lower_index = rng%start_index
            upper_index = rng%end_index
        type is (array_bounds_node)
            lower_index = rng%lower_bound_index
            upper_index = rng%upper_bound_index
        class default
            call parser%error_at_token( &
                'Invalid literal substring: expected a lower:upper range', source_token)
            return
        end select

        inner_len = 0
        escaped = .false.
        i = 1
        do while (i <= len(inner))
            if (inner(i:i) == quote) then
                if (i == len(inner)) return
                if (inner(i + 1:i + 1) /= quote) return
                escaped = .true.
                i = i + 1
            end if
            inner_len = inner_len + 1
            i = i + 1
        end do
        lo = 1
        up = inner_len
        lower_known = .true.
        upper_known = .true.
        if (lower_index > 0) then
            lower_known = literal_integer_value(arena, lower_index, lo, wrong_type)
            if (wrong_type) then
                call parser%error_at_token( &
                    'Invalid literal substring: bounds must be scalar integers', &
                    source_token)
                return
            end if
        end if
        if (upper_index > 0) then
            upper_known = literal_integer_value(arena, upper_index, up, wrong_type)
            if (wrong_type) then
                call parser%error_at_token( &
                    'Invalid literal substring: bounds must be scalar integers', &
                    source_token)
                return
            end if
        end if
        if (.not. lower_known .or. .not. upper_known) return
        ! Empty ranges are valid even when their endpoints lie outside the string.
        if (lo > up) then
            folded = push_array_slice(arena, base_expr, arg_indices, &
                                      size(arg_indices), close_token%line, close_token%column)
            return
        end if
        if (lo < 1 .or. up > inner_len) then
            call parser%error_at_token( &
                'Invalid literal substring bounds: '// &
                'nonempty range is outside the string', &
                source_token)
            return
        end if
        if (escaped) return
        ! Retain the literal base and bounds for independent adapters. Constant
        ! folding erased source structure and orphaned the range in strict mode.
        folded = push_array_slice(arena, base_expr, arg_indices, &
                                  size(arg_indices), close_token%line, close_token%column)
    end function fold_literal_substring

    recursive logical function literal_integer_value(arena, node_index, value, &
                                                     wrong_type) result(ok)
        type(ast_arena_t), intent(in) :: arena
        integer, intent(in) :: node_index
        integer(int64), intent(out) :: value
        logical, intent(out) :: wrong_type
        integer :: io_stat, kind_separator
        character(len=:), allocatable :: text

        ok = .false.
        wrong_type = .false.
        value = 0
        if (.not. arena%has_node_at(node_index)) return
        select type (lit => arena%entries(node_index)%node)
        type is (literal_node)
            if (lit%literal_kind /= LITERAL_INTEGER) then
                wrong_type = .true.
                return
            end if
            if (.not. allocated(lit%value)) return
            text = adjustl(lit%value)
            kind_separator = index(text, '_')
            if (kind_separator > 1) text = text(:kind_separator - 1)
            read(text, *, iostat=io_stat) value
            ok = io_stat == 0
        type is (binary_op_node)
            if (.not. lit%is_unary_minus) return
            ok = literal_integer_value(arena, lit%right_index, value, wrong_type)
            if (.not. ok) return
            if (value == -huge(value) - 1) then
                ok = .false.
                return
            end if
            value = -value
        end select
    end function literal_integer_value

    logical function any_range_argument(arena, arg_indices) result(found)
        type(ast_arena_t), intent(in) :: arena
        integer, intent(in) :: arg_indices(:)
        integer :: i

        found = .false.
        do i = 1, size(arg_indices)
            if (.not. arena%has_node_at(arg_indices(i))) cycle
            select type (node => arena%entries(arg_indices(i))%node)
                type is (range_expression_node)
                found = .true.
                return
            end select
        end do
    end function any_range_argument

    logical function base_is_literal(arena, base_expr) result(ok)
        type(ast_arena_t), intent(in) :: arena
        integer, intent(in) :: base_expr

        ok = .false.
        if (.not. arena%has_node_at(base_expr)) return
        select type (node => arena%entries(base_expr)%node)
            type is (literal_node)
            ok = .true.
        end select
    end function base_is_literal

    subroutine extract_target_name(arena, expr_index, call_name)
        type(ast_arena_t), intent(in) :: arena
        integer, intent(in) :: expr_index
        character(len=:), allocatable, intent(out) :: call_name

        if (.not. arena%has_node_at(expr_index)) return

        select type (node => arena%entries(expr_index)%node)
            type is (call_or_subscript_node)
            if (allocated(node%name)) then
                call_name = node%name
            end if
            type is (component_access_node)
            if (allocated(node%component_name)) then
                call_name = node%component_name
            end if
            type is (identifier_node)
            if (allocated(node%name)) then
                call_name = node%name
            end if
        end select
    end subroutine extract_target_name

end module parser_expression_arrays_module
