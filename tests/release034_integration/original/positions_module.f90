module original_positions
implicit none
interface true_pos
module procedure true_pos_func
end interface
interface set_alloc
module procedure set_alloc_int_vec
end interface
contains
function positions_char_string(string,char) result(ipos)
! return in ipos(:) the positions of char in string, where char is assumed to have length 1
character (len=*), intent(in)  :: string  ! string that is searched
character (len=*), intent(in)  :: char    ! character to look for in string
integer          , allocatable :: ipos(:) ! positions of char in string
logical                        :: tf(len(string))
integer                        :: i
forall (i=1:len(string)) tf(i) = string(i:i) == char
call set_alloc(true_pos(tf),ipos)
end function positions_char_string

function true_pos_func(tf) result(ipos)
! return in ipos the positions of the true elements in tf(:)
logical, intent(in) :: tf(:)
integer             :: ipos(count(tf))
integer             :: i,j
j = 0
do i=1,size(tf)
   if (tf(i)) then
      j = j + 1
      ipos(j) = i
   end if
end do
end function true_pos_func

pure recursive subroutine set_alloc_int_vec(ii,jj,jmin,jmax)
! for integer vectors xx(:) and yy(:), allocate yy and set it to xx
! keep only values between jmin and jmax, inclusive, if they are present
integer, intent(in)               :: ii(:)
integer, intent(out), allocatable :: jj(:)
integer, intent(in) , optional    :: jmin,jmax
integer                           :: ni
if (present(jmin) .and. present(jmax)) then
   call set_alloc_int_vec(pack(ii,ii >= jmin .and. ii <= jmax),jj)
else if (present(jmin)) then
   call set_alloc_int_vec(pack(ii,ii >= jmin),jj)
else if (present(jmax)) then
   call set_alloc_int_vec(pack(ii,ii <= jmax),jj)
else
   ni = size(ii)
!   print*,"size(ii)=",size(ii) ! debug
!   print*,"ni=",ni ! debug
   allocate (jj(ni))
   jj = ii
end if
end subroutine set_alloc_int_vec

subroutine assert_le(n1,n2,name1,name2,procedure)
! print an error message and stop if n1 > n2
integer          , intent(in) :: n1,n2
character (len=*), intent(in) :: procedure   ! name of program unit where assertion is made
character (len=*), intent(in) :: name1,name2 ! variable names 
if (n1 > n2) then
   write (*,"(a,2(1x,a),' =',2(1x,i0),a)") "in " // trim(procedure) // ",", &
          trim(name1),trim(name2),n1,n2," need " // trim(name1) // " <= " // trim(name2) // ", STOPPING"
   stop
end if
end subroutine assert_le

end module
