program p
integer,target::a(1,1,2),z
integer::ordinary(1,1,2)
a=3;ordinary=5;z=1
call work(a,z)
call work(ordinary,z)
call inspect()
call inspect(a)
print *,a,ordinary,z
contains
subroutine work(x,y)
integer,intent(inout),target::x(:,:,:)
integer,target,intent(out)::y
x=x+1;y=x(1,1,2)
end subroutine
subroutine inspect(x)
integer,optional,target,intent(in)::x(:,:,:)
print *,present(x)
if(present(x)) print *,x
end subroutine
end program
