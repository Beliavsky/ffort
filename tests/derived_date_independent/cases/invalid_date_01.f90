module month_date_mod
   implicit none
   private

   ! A date denotes a year and a month, with no day component.
   ! Valid years: 0..9999; valid months: 1..12.
   type, public :: date_t
      integer :: year
      integer :: month
   end type date_t

   public :: date_string, print_date, add_months
   public :: operator(+), operator(-)
   public :: operator(==), operator(/=), operator(<), operator(<=)
   public :: operator(>), operator(>=)

   ! A sufficiently wide kind prevents overflow for default-integer offsets.
   integer, parameter :: wide = selected_int_kind(15)
   integer(kind=wide), parameter :: months_per_year = 12
   integer(kind=wide), parameter :: max_month_index = 9999 * months_per_year + 11

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

   subroutine check_date(d)
      type(date_t), intent(in) :: d   ! date to validate
      if (d%year < 0 .or. d%year > 9999) stop 'Invalid year: expected 0..9999'
      if (d%month < 1 .or. d%month > 12) stop 'Invalid month: expected 1..12'
   end subroutine check_date

   function month_index(d) result(index)
      type(date_t), intent(in) :: d   ! date to convert to an index
      integer(kind=wide) :: index
      call check_date(d)
      index = months_per_year * int(d%year, kind=wide) &
           + int(d%month - 1, kind=wide)
   end function month_index

   function date_from_index(index) result(d)
      integer(kind=wide), intent(in) :: index  ! months since 0000-01
      type(date_t) :: d
      if (index < 0 .or. index > max_month_index) &
           stop 'Date arithmetic exceeds years 0..9999'
      d%year = int(index / months_per_year)
      d%month = int(modulo(index, months_per_year)) + 1
   end function date_from_index

   function date_string(d) result(s)
      type(date_t), intent(in) :: d   ! date to format
      character(len=7) :: s
      call check_date(d)
      write(s, '(I4.4,"-",I2.2)') d%year, d%month
   end function date_string

   subroutine print_date(d)
      type(date_t), intent(in) :: d   ! date to print on standard output
      print '(A)', date_string(d)
   end subroutine print_date

   function date_plus_months(d, n) result(res)
      type(date_t), intent(in) :: d   ! starting date
      integer, intent(in) :: n        ! signed months to add
      type(date_t) :: res
      res = date_from_index(month_index(d) + int(n, kind=wide))
   end function date_plus_months

   function months_plus_date(n, d) result(res)
      integer, intent(in) :: n        ! signed months to add
      type(date_t), intent(in) :: d   ! starting date
      type(date_t) :: res
      res = date_plus_months(d, n)
   end function months_plus_date

   function date_minus_months(d, n) result(res)
      type(date_t), intent(in) :: d   ! starting date
      integer, intent(in) :: n        ! signed months to subtract
      type(date_t) :: res
      res = date_from_index(month_index(d) - int(n, kind=wide))
   end function date_minus_months

   function date_minus_date(a, b) result(n)
      type(date_t), intent(in) :: a   ! first date
      type(date_t), intent(in) :: b   ! date to subtract
      integer :: n
      ! The supported year range bounds the difference to +/-119999.
      n = int(month_index(a) - month_index(b))
   end function date_minus_date

   subroutine add_months(d, n)
      type(date_t), intent(inout) :: d   ! date modified in place
      integer, intent(in) :: n           ! signed months to add
      d = d + n
   end subroutine add_months

   logical function date_equal(a, b)
      type(date_t), intent(in) :: a   ! first date
      type(date_t), intent(in) :: b   ! second date
      date_equal = month_index(a) == month_index(b)
   end function date_equal

   logical function date_not_equal(a, b)
      type(date_t), intent(in) :: a   ! first date
      type(date_t), intent(in) :: b   ! second date
      date_not_equal = month_index(a) /= month_index(b)
   end function date_not_equal

   logical function date_less(a, b)
      type(date_t), intent(in) :: a   ! first date
      type(date_t), intent(in) :: b   ! second date
      date_less = month_index(a) < month_index(b)
   end function date_less

   logical function date_less_equal(a, b)
      type(date_t), intent(in) :: a   ! first date
      type(date_t), intent(in) :: b   ! second date
      date_less_equal = month_index(a) <= month_index(b)
   end function date_less_equal

   logical function date_greater(a, b)
      type(date_t), intent(in) :: a   ! first date
      type(date_t), intent(in) :: b   ! second date
      date_greater = month_index(a) > month_index(b)
   end function date_greater

   logical function date_greater_equal(a, b)
      type(date_t), intent(in) :: a   ! first date
      type(date_t), intent(in) :: b   ! second date
      date_greater_equal = month_index(a) >= month_index(b)
   end function date_greater_equal

end module month_date_mod

program date_edge
   use month_date_mod
   implicit none
   print '(a)', 'BEFORE'
   print '(a)', date_string(date_t(10000,1))
   print '(a)', 'AFTER'
end program date_edge
