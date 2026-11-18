subroutine write_lines_file(xfile,lines,format_str,format_header)
character (len=*), intent(in), optional :: xfile
character (len=*), intent(in), optional :: lines(:)
character (len=*), intent(in), optional :: format_str,format_header
integer                                 :: outu
integer                                 :: nskip
nskip = 0
call get_unit_open_file(xfile,outu,xaction="w",nlines_skip_append=nskip)
call write_lines(outu,lines,format_str,format_header)
end subroutine write_lines_file
!
