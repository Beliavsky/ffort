program kinds_empty_direct_selector
implicit none
real(kind=selected_real_kind()) :: x
real(SELECTED_REAL_KIND()) :: y
integer(kind=selected_real_kind()) :: i
x=1.25
y=2.5
i=7
print *,kind(x),kind(y),kind(i),x,y,i
end program
