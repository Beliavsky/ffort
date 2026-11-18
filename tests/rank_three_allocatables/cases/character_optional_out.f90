program p
character(:),allocatable::a(:,:,:)
call fill()
call fill(a)
print *,allocated(a),len(a),size(a),lbound(a,3)
call fill(a)
contains
subroutine fill(x)
character(:),allocatable,optional,intent(out)::x(:,:,:)
print *,present(x)
if(present(x)) then
print *,allocated(x)
allocate(character(2)::x(1,1,-1:0)); x='ok'
end if
end subroutine
end program
