program main

implicit none

print '(a)','before'
error stop 'explicit test failure'
print *,999
end program main
