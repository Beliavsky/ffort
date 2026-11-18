program model_descriptors
implicit none
real,allocatable :: a(:),b(:,:,:)
real,pointer :: p(:)
nullify(p)
print *,epsilon(a),tiny(b),huge(p),radix(p)
allocate(a(0))
allocate(b(1,2,3))
print *,epsilon(a),tiny(b),huge(a),radix(b)
call inspect()
call inspect(a)
call allocation()
call allocation(b)
contains
subroutine inspect(x)
real,optional,intent(in) :: x(:)
print *,present(x),epsilon(x),tiny(x),huge(x),radix(x)
print *,floor(1.5,kind=2*radix(x))
end subroutine
subroutine allocation(x)
real,optional,allocatable,intent(in) :: x(:,:,:)
print *,present(x),epsilon(x),tiny(x),huge(x),radix(x)
print *,floor(1.5,kind=2*radix(x))
end subroutine
end program
