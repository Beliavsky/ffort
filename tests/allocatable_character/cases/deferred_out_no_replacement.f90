program main
implicit none
character(:),allocatable::a(:)
a=['ab','cd']
call clear(a)
print *,allocated(a)
a=['z']
print *,len(a),size(a)
contains
subroutine clear(x)
character(:),allocatable,intent(out)::x(:)
if(allocated(x)) error stop 1
end subroutine

end program
