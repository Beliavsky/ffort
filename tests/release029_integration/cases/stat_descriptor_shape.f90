! Synthetic release 0.29 composition fixture; not an extracted utility body.
program composition
implicit none
integer,allocatable::a(:,:,:)
integer::status
allocate(a(-1:0,4:5,7:8))
a=6
call retry(a)
print *,shape(a),lbound(a,1),lbound(a,2),lbound(a,3),sum(a(:,:,7))
deallocate(a,stat=status)
print *,status,allocated(a)
contains
subroutine retry(x)
integer,allocatable,intent(in out)::x(:,:,:)
integer::code,before(3)
before=shape(x)
allocate(x(1,1,1),stat=code)
print *,code/=0,all(shape(x)==before),shape(x)
where(x(:,:,7)>0) x(:,:,7)=x(:,:,7)-1
end subroutine
end program
