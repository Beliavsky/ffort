program demo_select_case
   implicit none

   integer, parameter :: numbers(7) = [-3, 0, 2, 5, 6, 10, 13]
   integer :: i, n
   character(len=10) :: color
   character(len=1) :: grade
   logical :: passed

   ! 1. Integer SELECT CASE
   print '(a)', 'Integer selector:'

   do i = 1, size(numbers)
      n = numbers(i)

      select case (n)
      case (:-1)              ! All negative integers
         print '(i3,2x,a)', n, 'negative'

      case (0)                ! Single value
         print '(i3,2x,a)', n, 'zero'

      case (1:3)              ! Inclusive range
         print '(i3,2x,a)', n, 'between 1 and 3'

      case (4, 6, 8)          ! Multiple discrete values
         print '(i3,2x,a)', n, '4, 6, or 8'

      case (9:12)            ! Another inclusive range
         print '(i3,2x,a)', n, 'between 9 and 12'

      case (13:)             ! Open-ended upper range
         print '(i3,2x,a)', n, '13 or greater'

      case default           ! No other case matches
         print '(i3,2x,a)', n, 'other positive integer'
      end select
   end do

   ! 2. Character SELECT CASE
   print '(a)', 'Character selector:'

   color = 'blue'

   select case (trim(color))
   case ('red', 'blue')
      print '(a)', 'A primary color'
   case ('green')
      print '(a)', 'Green'
   case default
      print '(a)', 'Other color'
   end select

   ! 3. Character ranges
   grade = 'C'

   select case (grade)
   case ('A')
      print '(a)', 'Excellent'
   case ('B':'D')
      print '(a)', 'Passing grade B-D'
   case default
      print '(a)', 'Other grade'
   end select

   ! 4. Logical SELECT CASE
   print '(a)', 'Logical selector:'

   passed = .true.

   select case (passed)
   case (.true.)
      print '(a)', 'Passed'
   case (.false.)
      print '(a)', 'Did not pass'
   end select

   ! 5. Expression as selector
   print '(a)', 'Expression as selector:'

   n = 7

   select case (mod(n, 2))
   case (0)
      print '(a)', 'Even'
   case (1)
      print '(a)', 'Odd'
   end select

end program demo_select_case
