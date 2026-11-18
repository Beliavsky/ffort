program p
integer::a(6)=0
call update(a(6:2:-2),[.true.,.false.,.true.])
print *,a
contains
pure subroutine update(a,m)
integer,intent(inout)::a(:)
logical,intent(in)::m(:)
where(m)
a=7
elsewhere
a=3
end where
end subroutine
end program
