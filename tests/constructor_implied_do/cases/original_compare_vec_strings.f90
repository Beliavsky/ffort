module original_compare_wrapper
implicit none
interface default
module procedure default_character
end interface
contains
subroutine compare_vec_strings(xx,yy,xname,yname)
! list which elements of xx are not in yy and which elements of yy are not in xx
character (len=*), intent(in) :: xx(:),yy(:)
character (len=*), intent(in), optional :: xname,yname
character (len=100) :: xname_,yname_
logical             :: x_not_in_y(size(xx))
integer             :: i,nx,ny,nx_not_in_y
xname_ = default("x",xname)
yname_ = default("y",yname)
nx = size(xx)
ny = size(yy)
x_not_in_y = [(all(yy/=xx(i)),i=1,size(xx))]
nx_not_in_y = count(x_not_in_y)
if (nx_not_in_y == 0) then
   write (*,*) "all elements of " // trim(xname_) // " are in " // trim(yname_)
else
   write (*,*) nx_not_in_y," elements of " // trim(xname_) // " not in " // trim(yname_) // ":"
   do i=1,nx
      if (x_not_in_y(i)) write (*,*) trim(xx(i))
   end do
   write (*,*)
end if
call compare_vec_strings_(yy,xx,yname,xname)
end subroutine compare_vec_strings

subroutine compare_vec_strings_(xx,yy,xname,yname)
character (len=*), intent(in) :: xx(:),yy(:)
character (len=*), intent(in), optional :: xname,yname
character (len=100) :: xname_,yname_
logical             :: x_not_in_y(size(xx))
integer             :: i,nx,ny,nx_not_in_y
xname_ = default("x",xname)
yname_ = default("y",yname)
nx = size(xx)
ny = size(yy)
x_not_in_y = [(all(yy/=xx(i)),i=1,size(xx))]
nx_not_in_y = count(x_not_in_y)
if (nx_not_in_y == 0) then
   write (*,*) "all elements of " // trim(xname_) // " are in " // trim(yname_)
else
   write (*,*) nx_not_in_y," elements of " // trim(xname_) // " not in " // trim(yname_) // ":"
   do i=1,nx
      if (x_not_in_y(i)) write (*,*) trim(xx(i))
   end do
   write (*,*)
end if
end subroutine compare_vec_strings_

elemental function default_character(def,opt) result(yy)
! return opt if it is present, otherwise def (character arguments and result)
character (len=*), intent(in)           :: def
character (len=*), intent(in), optional :: opt
character (len=len(def))                :: yy
if (present(opt)) then
   yy = opt
else
   yy = def
end if
end function default_character
end module
program main
use original_compare_wrapper
implicit none
character(3)::x(4),y(3),empty(0),one(1)
x=["cat","dog","cat","   "]
y=["dog","owl","   "]
one=["cat"]
print '(a)',"CASE defaults mixed"
call compare_vec_strings(x,y)
print '(a)',"CASE equal duplicates"
call compare_vec_strings(x,x,"left","right")
print '(a)',"CASE both empty"
call compare_vec_strings(empty,empty)
print '(a)',"CASE left empty"
call compare_vec_strings(empty,one)
print '(a)',"CASE right empty"
call compare_vec_strings(one,empty,"source",yname="target")
print '(a)',"CASE trailing spaces"
call compare_vec_strings([character(5)::"cat"],one)
end program
