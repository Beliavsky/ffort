program p
implicit none
character(1024)::cwd
integer::s
call getcwd(cwd,s)
if(s/=0.or.len_trim(cwd)==0)error stop 1
print '(a,t10,l1)','cwd=',lle(cwd,cwd//' ')
end program
