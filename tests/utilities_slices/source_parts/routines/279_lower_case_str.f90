elemental function lower_case_str(input_string) result(output_string)
! convert string to lower case
character(*), intent(in)     :: input_string
character(len(input_string)) :: output_string
integer                      :: i, n 
output_string = input_string
do i = 1, len(output_string)
   ! -- find location of letter in upper case constant string
   n = index(upper_case, output_string(i:i))
   ! -- if current substring is an upper case letter, make it lower case
   if (n /= 0) output_string(i:i) = lower_case(n:n)
end do
end function lower_case_str
!
