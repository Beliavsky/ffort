module utility_closure
implicit none
integer,parameter::dp=kind(1d0)
character(*),parameter::mod_str="utilities, "
interface set_optional
module procedure set_optional_integer
end interface
interface set_alloc
module procedure set_alloc_real_tensor
end interface
contains
subroutine select_tensor_real(iuse,xx,idim)
! select elements in positions iuse along dimension idim
integer      , intent(in)                  :: iuse(:)
real(kind=dp), intent(in out), allocatable :: xx(:,:,:)
integer      , intent(in)    , optional    :: idim
integer                                    :: idim_
character (len=*), parameter               :: msg=mod_str//"select_tensor_real, "
call set_optional(idim_,1,idim)
select case (idim_)
   case (1); call set_alloc((xx(iuse,:,:)),xx)
   case (2); call set_alloc((xx(:,iuse,:)),xx)
   case (3); call set_alloc((xx(:,:,iuse)),xx)
   case default
      write (*,*) msg,"idim_ =",idim_," should be between 1 and 3, stopPinG"
      stop
end select
end subroutine select_tensor_real

elemental subroutine set_optional_integer(i,idef,iopt)
! set i to (iopt,idef) if iopt (is,is not) PRESENT
integer, intent(out)          :: i
integer, intent(in)           :: idef
integer, intent(in), optional :: iopt
if (present(iopt)) then
   i = iopt
else
   i = idef
end if
end subroutine set_optional_integer

subroutine set_alloc_real_tensor(xx,yy)
! for real tensors xx(:,:,:) and yy(:,:,:), allocate yy and set it to xx
real(kind=dp) , intent(in)               :: xx(:,:,:)
real(kind=dp) , intent(out), allocatable :: yy(:,:,:)
allocate (yy(size(xx,1),size(xx,2),size(xx,3)))
yy = xx
end subroutine set_alloc_real_tensor
end module
program p
use utility_closure
implicit none
real(dp),allocatable::a(:,:,:)
integer::axis,empty(0),expected(3)
do axis=1,3
allocate(a(3,3,3))
a=1
call select_tensor_real(empty,a,axis)
expected=[3,3,3]
expected(axis)=0
if(any(shape(a)/=expected))error stop 1
call select_tensor_real(empty,a,axis)
if(any(shape(a)/=expected))error stop 2
deallocate(a)
end do
print '(i0)',1
end program
