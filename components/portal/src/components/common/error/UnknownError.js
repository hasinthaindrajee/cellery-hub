/*
 * Copyright (c) 2019, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

import ArrowBack from "@material-ui/icons/ArrowBack";
import Button from "@material-ui/core/Button/Button";
import CelleryError from "../../../img/celleryError.jpg";
import Home from "@material-ui/icons/Home";
import React from "react";
import {withRouter} from "react-router-dom";
import {withStyles} from "@material-ui/core";
import * as PropTypes from "prop-types";

const styles = (theme) => ({
    unknownErrorContainer: {
        position: "relative",
        top: 0,
        left: 0,
        height: "100%",
        width: "100%",
        display: "grid"
    },
    unknownError: {
        margin: "auto",
        textAlign: "center"
    },
    unknownErrorImg: {
        marginTop: theme.spacing.unit * 5,
        height: 150
    },
    unknownErrorTitle: {
        margin: theme.spacing.unit,
        fontSize: "1.5em",
        fontWeight: 400,
        color: "#6e6e6e"
    },
    unknownErrorDescription: {
        fontSize: "1em",
        fontWeight: 300,
        color: "#808080",
        maxWidth: "50vw"
    },
    navigationButtonsContainer: {
        margin: theme.spacing.unit * 3
    },
    navigationButton: {
        margin: theme.spacing.unit
    },
    navigationButtonIcon: {
        marginRight: theme.spacing.unit
    }
});

const UnknownError = ({classes, history, title, description, showNavigationButtons}) => (
    <div className={classes.unknownErrorContainer}>
        <div className={classes.unknownError}>
            <img src={CelleryError} className={classes.unknownErrorImg} alt={"Unknown Error"}/>
            <div className={classes.unknownErrorTitle}>
                {title ? title : "Something Went Wrong"}
            </div>
            {
                description
                    ? (
                        <div className={classes.unknownErrorDescription}>
                            {description}
                        </div>
                    )
                    : null
            }
            {
                showNavigationButtons
                    ? (
                        <div className={classes.navigationButtonsContainer}>
                            <Button variant={"outlined"} size={"small"} className={classes.navigationButton}
                                onClick={() => history.goBack()}>
                                <ArrowBack className={classes.navigationButtonIcon}/>
                                Go Back
                            </Button>
                            <Button variant={"outlined"} size={"small"} className={classes.navigationButton}
                                onClick={() => history.push("/")}>
                                <Home fontSize={"small"} className={classes.navigationButtonIcon}/>
                                Home
                            </Button>
                        </div>
                    )
                    : null
            }
        </div>
    </div>
);

UnknownError.propTypes = {
    classes: PropTypes.object.isRequired,
    history: PropTypes.shape({
        goBack: PropTypes.func.isRequired,
        push: PropTypes.func.isRequired
    }),
    title: PropTypes.string,
    description: PropTypes.string,
    showNavigationButtons: PropTypes.bool
};

export default withStyles(styles, {withTheme: true})(withRouter(UnknownError));
