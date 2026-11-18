function assert_eqn(nn,string)
character(len=*), intent(in) :: string
integer, dimension(:), intent(in) :: nn
integer :: assert_eqn
if (all(nn(2:) == nn(1))) then
   assert_eqn=nn(1)
else
   write (*,*) "nrerror: an assert_eq failed with this tag:", string
stop "program terminated by assert_eqn"
end if
end function assert_eqn
!
