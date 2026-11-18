program main
implicit none
integer::i
character(4096)::a
write(*,'(a)') "before"
a="x"
print '(4096a1,a1)', (a,i=1,4096),"z"
end program
