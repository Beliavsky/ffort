program main
integer,allocatable::a(:)
print *,kind(a),kind(allocated(a)),allocated(a)
end program
