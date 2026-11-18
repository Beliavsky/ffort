program p
logical::v(3),m(2,2),t(2,1,2),empty(2,1,0)
logical,allocatable::a(:),b(:,:),c(:,:,:)
v=[.true.,.false.,.true.]
m=reshape([.false.,.true.,.true.,.false.],[2,2])
t=.true.;t(2,1,2)=.false.
call set_alloc_logical_vec(v,a)
call set_alloc_logical_matrix(m,b)
call set_alloc_logical_tensor(t,c)
print *,a,b,c
print *,size(a),size(b,1),size(b,2),size(c,1),size(c,2),size(c,3)
a=.false.;b=.false.;c=.false.
call set_alloc_logical_vec(v,a)
call set_alloc_logical_matrix(m,b)
call set_alloc_logical_tensor(t,c)
print *,a,b,c
call set_alloc_logical_tensor(empty,c)
print *,allocated(c),size(c),size(c,1),size(c,2),size(c,3)
contains
subroutine set_alloc_logical_vec(xx,yy)
logical, intent(in) :: xx(:)
logical, intent(out), allocatable :: yy(:)
integer             :: n
n = size(xx)
allocate (yy(n))
yy = xx
end subroutine set_alloc_logical_vec
subroutine set_alloc_logical_matrix(xx,yy)
logical, intent(in)               :: xx(:,:)
logical, intent(out), allocatable :: yy(:,:)
allocate (yy(size(xx,1),size(xx,2)))
yy = xx
end subroutine set_alloc_logical_matrix
subroutine set_alloc_logical_tensor(xx,yy)
logical, intent(in)               :: xx(:,:,:)
logical, intent(out), allocatable :: yy(:,:,:)
allocate (yy(size(xx,1),size(xx,2),size(xx,3)))
yy = xx
end subroutine set_alloc_logical_tensor
end program
