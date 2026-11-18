! Synthetic release 0.32 composition fixture; no original utility body.
program main
implicit none
integer,target::a(3,2)
integer,pointer::p(:),q(:)
a=reshape([1,2,3,4,5,6],[3,2])
p=>a(:,2)
q=>a(2,:)
call update(a,2)
print *,p,q
where(p>5) p=p+1
print *,a,shape(a),shape(p),findloc(a,41)
contains
subroutine update(x,n)
integer,intent(in)::n
integer,target,intent(out)::x(n,2)
x=reshape([10,20,30,40],[2,2])
end subroutine
end program
