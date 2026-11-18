program p
implicit none
integer::u
character(4)::a,b
u=27
call take_line(u,a)
call take_line(u,b)
if(a/='one'.or.b/='two')stop 1
print '(a)', 'OK'
contains
subroutine take_line(iu,line)
integer,intent(in)::iu
character(*),intent(out)::line
read(iu,'(a)')line
end subroutine
end program
