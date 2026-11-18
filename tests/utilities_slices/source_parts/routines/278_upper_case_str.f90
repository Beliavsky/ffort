elemental function upper_case_str(input_string) result(output_string)
! convert string to upper case
character(*), intent(in)     :: input_string
character(len(input_string)) :: output_string
integer                      :: i, n
output_string = input_string
do i = 1, len(output_string)
   ! -- find location of letter in lower case constant string
   n = index(lower_case, output_string(i:i))
   ! -- if current substring is a lower case letter, make it upper case
   if (n /= 0) output_string(i:i) = upper_case(n:n)
end do
end function upper_case_str
!
