module LoggerTool
    """
    A simple logging tool to help make simulator output consistent.
    Levels:
        0 - Errors
        1 - Warnings
        2 - Info
        3 - Debug
    """
    
    type LoggerInstance
        stdout::Bool
        fileio::Bool
        filename::String
        level::Int
        fileptr::IOStream

        function LoggerInstance(
            stdout::Bool,
            fileio::Bool,
            filename::String,
            level::Int
        )
            if fileio == true
                fileptr = open(filename, "w+")
                new(stdout, fileio, filename, level, fileptr)
            else
                new(stdout, fileio, filename, level)
            end
        end
    end

    ERROR_LEVEL = 0
    WARNING_LEVEL = 1
    INFO_LEVEL = 2
    DEBUG_LEVEL = 3

    MESSAGE_LABELS = {
        0 => "ERROR",
        1 => "WARN",
        2 => "INFO",
        3 => "DEBUG",
    }
    RESET_COLOR = "\u001b[0m"
    MESSAGE_COLORS = { 
        0 => "\u001b[31m",
        1 => "\u001b[33m",
        2 => "\u001b[34m", 
        3 => "\u001b[35m"        
    }


    function setup(
        stdout::Bool, 
        fileio::Bool, 
        level::Int = 3, 
        filename::String = "log.txt")
        """
        LoggerInstance constructor helper
        """
        return LoggerInstance(stdout, fileio, filename, level)
    end
    
    
    function log(logger::LoggerInstance, msg_level::Int, message::Any)
        """
        Writes a message, at a given level, to file and stdout as defined by the logger settings

        Parameters
        ----------
        logger : LoggerInstance
            Instance of LoggerInstance
        msg_level : int
            The level of the message, as defined above. Lower is more serious.
        message : string
            The message itself
        """
        log_time = strftime("%Y-%m-%dT%H:%M:%S", time())
        if logger.stdout == true
            output_message = string(
                "[", log_time, "]",
                MESSAGE_COLORS[msg_level],
                "[", MESSAGE_LABELS[msg_level], "]",
                RESET_COLOR, ": ",
                message)
            println(output_message)
        end
        if logger.fileio == true
            output_message = string(
                "[", log_time, "][", MESSAGE_LABELS[msg_level], "]: ",
                message, 
                "\n")
            seekend(logger.fileptr)
            write(logger.fileptr, output_message)
            flush(logger.fileptr)
        end
    end

    function error(logger::LoggerInstance, message::Any)
        """
        Log an error
        """
        if logger.level >= ERROR_LEVEL
            log(logger, ERROR_LEVEL, message)
        end
    end

    function warn(logger::LoggerInstance, message::Any)
        """
        Log a warning
        """
        if logger.level >= WARNING_LEVEL
            log(logger, WARNING_LEVEL, message)
        end
    end

    function info(logger::LoggerInstance, message::Any)
        """
        Log an info message
        """
        if logger.level >= INFO_LEVEL
            log(logger, INFO_LEVEL, message)
        end
    end

    function debug(logger::LoggerInstance, message::Any)
        """
        Log debug output
        """
        if logger.level >= DEBUG_LEVEL
            log(logger, DEBUG_LEVEL, message)
        end
    end

    function close(logger::LoggerInstance)
        """
        Close the logger. Call when the logger is no longer needed.
        """
        if logger.fileio == true
           Base.close(logger.fileptr)
        end
    end
end