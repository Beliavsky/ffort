program purity_test
implicit none

print *,991
contains
pure integer function compute(xx) result(rr)
integer,intent(in)::xx
integer,save::state
rr=xx
end function compute

end program
