program p
implicit none
character(4)::s
write(s,'(g0,*(i0))')'h',1,2,3
if(s/='h123')error stop 1
print '(a)','ok'
end program
