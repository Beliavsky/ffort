program keyword_oracle
implicit none
integer :: aa,bb
aa=2
call transform(result_arg=bb,input_arg=aa)
print *,aa,bb
contains
subroutine transform(input_arg,result_arg)
integer,intent(inout) :: input_arg
integer,intent(out) :: result_arg
call next_step(output_value=result_arg,input_value=input_arg)
input_arg=input_arg+1
end subroutine transform
subroutine next_step(input_value,output_value)
integer,intent(in) :: input_value
integer,intent(out) :: output_value
output_value=input_value*3
end subroutine next_step

end program
