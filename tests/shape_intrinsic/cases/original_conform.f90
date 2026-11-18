program p
implicit none
integer,parameter::dp=kind(1.0d0)
real(dp)::a(3),b(3),c(2),x(2,3),y(2,3),z(3,2),u(2,1,3),v(2,1,3),w(1,2,3)
a=0
b=0
c=0
x=0
y=0
z=0
u=0
v=0
w=0
print *,conform_real_1d(a,b),conform_real_1d(a,c)
print *,conform_real_2d(x,y),conform_real_2d(x,z),conform_real_2d(x)
print *,conform_real_3d(u,v),conform_real_3d(u,w)
print *,conform_optional_real_2d(x,y),conform_optional_real_2d(x,z),conform_optional_real_2d(x)
contains
function conform_real_1d(xx,yy) result(tf)
! check that two vectors are conformable
real(kind=dp), intent(in) :: xx(:),yy(:)
logical                   :: tf
tf = all(shape(xx) == shape(yy))
end function conform_real_1d
function conform_real_2d(xx,yy) result(tf)
! check that two matrices are conformable
real(kind=dp), intent(in)           :: xx(:,:)
real(kind=dp), intent(in), optional :: yy(:,:)
logical                             :: tf
if (present(yy)) then
   tf = all(shape(xx) == shape(yy))
else
   tf = .true.
end if
end function conform_real_2d
function conform_real_3d(xx,yy) result(tf)
! check that two matrices are conformable
real(kind=dp), intent(in) :: xx(:,:,:),yy(:,:,:)
logical                   :: tf
tf = all(shape(xx) == shape(yy))
end function conform_real_3d
function conform_optional_real_2d(xx,yy) result(tf)
! check that two matrices are conformable if they are present
real(kind=dp), intent(in)           :: xx(:,:)
real(kind=dp), intent(in), optional :: yy(:,:)
logical                             :: tf
if (present(yy)) then
   tf = all(shape(xx) == shape(yy))
else
   tf = .true.
end if
end function conform_optional_real_2d

end program
