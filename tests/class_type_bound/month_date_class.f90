module month_date_mod
   use, intrinsic :: iso_fortran_env, only : int64
   implicit none
   private

   public :: date_t
   public :: operator(+), operator(-)
   public :: operator(==), operator(/=), operator(<), operator(<=)
   public :: operator(>), operator(>=)

   ! Represents a calendar month (not a particular day).
   ! Supported years are 0000 to 9999; months are 1 to 12.
   type :: date_t
      integer :: year
      integer :: month
   contains
      procedure :: to_string
      procedure :: add_months => advance_months
      procedure, private :: write_formatted
      generic :: write(formatted) => write_formatted
   end type date_t

   interface operator(+)
      module procedure date_plus_months
      module procedure months_plus_date
   end interface

   interface operator(-)
      module procedure date_minus_months
      module procedure date_minus_date
   end interface

   interface operator(==)
      module procedure date_equal
   end interface
   interface operator(/=)
      module procedure date_not_equal
   end interface
   interface operator(<)
      module procedure date_less
   end interface
   interface operator(<=)
      module procedure date_less_equal
   end interface
   interface operator(>)
      module procedure date_greater
   end interface
   interface operator(>=)
      module procedure date_greater_equal
   end interface

contains

   pure subroutine check_date(d)
      type(date_t), intent(in) :: d    ! date to validate
      if (d%year < 0 .or. d%year > 9999) error stop 'year must be 0..9999'
      if (d%month < 1 .or. d%month > 12) error stop 'month must be 1..12'
   end subroutine check_date

   pure integer(int64) function month_index(d) result(index)
      type(date_t), intent(in) :: d    ! date to convert to a month index
      call check_date(d)
      index = 12_int64 * int(d%year, int64) + int(d%month - 1, int64)
   end function month_index

   pure function from_index(index) result(d)
      integer(int64), intent(in) :: index    ! zero-based month index
      type(date_t) :: d
      integer(int64) :: y

      ! MODULO, unlike MOD, gives a nonnegative remainder for a positive divisor.
      y = (index - modulo(index, 12_int64)) / 12_int64
      if (y < 0_int64 .or. y > 9999_int64) error stop 'date arithmetic exceeds supported years'
      d%year = int(y)
      d%month = int(modulo(index, 12_int64)) + 1
   end function from_index

   pure function to_string(this) result(s)
      class(date_t), intent(in) :: this    ! date to format
      character(len=7) :: s
      call check_date(date_t(this%year, this%month))
      write(s, '(i4.4, "-", i2.2)') this%year, this%month
   end function to_string

   subroutine write_formatted(dtv, unit, iotype, v_list, iostat, iomsg)
      class(date_t), intent(in) :: dtv    ! date being written
      integer, intent(in) :: unit       ! Fortran I/O unit
      character(len=*), intent(in) :: iotype ! LISTDIRECTED, DT, etc.
      integer, intent(in) :: v_list(:)  ! DT descriptor parameters (unused)
      integer, intent(out) :: iostat    ! I/O status
      character(len=*), intent(inout) :: iomsg ! I/O diagnostic
      write(unit, '(a)', iostat=iostat, iomsg=iomsg) dtv%to_string()
   end subroutine write_formatted

   pure function date_plus_months(d, n) result(res)
      type(date_t), intent(in) :: d    ! starting date
      integer, intent(in) :: n         ! months to add; may be negative
      type(date_t) :: res
      res = from_index(month_index(d) + int(n, int64))
   end function date_plus_months

   pure function months_plus_date(n, d) result(res)
      integer, intent(in) :: n         ! months to add; may be negative
      type(date_t), intent(in) :: d    ! starting date
      type(date_t) :: res
      res = date_plus_months(d, n)
   end function months_plus_date

   pure function date_minus_months(d, n) result(res)
      type(date_t), intent(in) :: d    ! starting date
      integer, intent(in) :: n         ! months to subtract; may be negative
      type(date_t) :: res
      res = from_index(month_index(d) - int(n, int64))
   end function date_minus_months

   pure integer function date_minus_date(a, b) result(n)
      type(date_t), intent(in) :: a    ! later date (for positive result)
      type(date_t), intent(in) :: b    ! date to subtract
      ! The restricted year range ensures the result fits default INTEGER.
      n = int(month_index(a) - month_index(b))
   end function date_minus_date

   pure subroutine advance_months(this, n)
      class(date_t), intent(inout) :: this ! date modified in place
      integer, intent(in) :: n             ! months to advance, may be negative
      type(date_t) :: res
      res = from_index(month_index(date_t(this%year, this%month)) + int(n, int64))
      this%year = res%year
      this%month = res%month
   end subroutine advance_months

   pure logical function date_equal(a, b)
      type(date_t), intent(in) :: a, b
      date_equal = month_index(a) == month_index(b)
   end function date_equal

   pure logical function date_not_equal(a, b)
      type(date_t), intent(in) :: a, b
      date_not_equal = month_index(a) /= month_index(b)
   end function date_not_equal

   pure logical function date_less(a, b)
      type(date_t), intent(in) :: a, b
      date_less = month_index(a) < month_index(b)
   end function date_less

   pure logical function date_less_equal(a, b)
      type(date_t), intent(in) :: a, b
      date_less_equal = month_index(a) <= month_index(b)
   end function date_less_equal

   pure logical function date_greater(a, b)
      type(date_t), intent(in) :: a, b
      date_greater = month_index(a) > month_index(b)
   end function date_greater

   pure logical function date_greater_equal(a, b)
      type(date_t), intent(in) :: a, b
      date_greater_equal = month_index(a) >= month_index(b)
   end function date_greater_equal

end module month_date_mod

program test_month_date
   use month_date_mod, only : date_t, operator(+), operator(-), &
      operator(==), operator(/=), operator(<), operator(<=), &
      operator(>), operator(>=)
   implicit none
   type(date_t) :: d1, d2, d3
   integer :: n

   d1 = date_t(2026, 11)
   d2 = date_t(2025, 8)
   n = d1 - d2

   print '(a, dt)', 'd1 = ', d1
   print *, 'list-directed d1 = ', d1
   print '(a, dt)', 'd2 = ', d2
   print '(a, i0)', 'd1 - d2 (months) = ', n
   print '(a, dt)', 'd1 +  3 = ', d1 + 3
   print '(a, dt)', ' 3 + d1 = ', 3 + d1
   print '(a, dt)', 'd1 - 14 = ', d1 - 14

   d3 = date_t(2026, 12)
   call d3%add_months(2)
   print '(a, dt)', 'after advancing 2026-12 by 2 months: ', d3

   if (d1%to_string() /= '2026-11') error stop 'format test failed'
   if (d1 + 3 /= date_t(2027, 2)) error stop 'addition test failed'
   if (d1 - 14 /= date_t(2025, 9)) error stop 'subtraction test failed'
   if (d1 - d2 /= 15) error stop 'month difference test failed'
   if (d2 - d1 /= -15) error stop 'negative month difference test failed'
   if (d3 /= date_t(2027, 2)) error stop 'in-place advancement failed'
   if (.not. (d1 == date_t(2026, 11))) error stop '== failed'
   if (.not. (d1 /= d2)) error stop '/= failed'
   if (.not. (d2 < d1)) error stop '< failed'
   if (.not. (d2 <= d1)) error stop '<= failed'
   if (.not. (d1 > d2)) error stop '> failed'
   if (.not. (d1 >= d1)) error stop '>= failed'
   if (date_t(2026, 1) - 1 /= date_t(2025, 12)) error stop 'year rollover failed'
   if (date_t(2025, 12) + 13 /= date_t(2027, 1)) error stop 'multi-year rollover failed'
   if (date_t(2025, 1) + (-14) /= date_t(2023, 11)) error stop 'negative addition failed'

   print '(a)', 'All tests passed.'
end program test_month_date
